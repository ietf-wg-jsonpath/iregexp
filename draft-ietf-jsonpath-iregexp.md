---
v: 3

title: >
  I-Regexp: An Interoperable Regexp Format
abbrev: I-Regexp
docname: draft-ietf-jsonpath-iregexp-latest
date: 2023-02-04

keyword: Internet-Draft
cat: std
consensus: true
submissiontype: IETF

venue:
  mail: JSONPath@ietf.org
  github: ietf-wg-jsonpath/iregexp

author:
  - name: Carsten Bormann
    org: Universität Bremen TZI
    street: Postfach 330440
    city: Bremen
    code: D-28359
    country: Germany
    phone: +49-421-218-63921
    email: cabo@tzi.org
  - name: Tim Bray
    org: Textuality
    country: Canada
    email: tbray@textuality.com

normative:
  XSD-2: W3C.REC-xmlschema-2-20041028
  XSD11-2: W3C.REC-xmlschema11-2-20120405
  RFC5234: abnf
  RFC7405: abnf-cs

informative:
  I-D.ietf-jsonpath-base: jsonpath
  RE2:
    title: >
      RE2 is a fast, safe, thread-friendly alternative to backtracking regular expression engines like those used in PCRE, Perl, and Python. It is a C++ library.
    target: "https://github.com/google/re2"
  PCRE2:
    title: >
      Perl-compatible Regular Expressions (revised API: PCRE2)
    target: "http://pcre.org/current/doc/html/"
  ECMA-262:
    target: https://www.ecma-international.org/wp-content/uploads/ECMA-262.pdf
    title: ECMAScript 2020 Language Specification
    author:
    - org: Ecma International
    date: 2020-06
    seriesinfo:
      ECMA: Standard ECMA-262, 11th Edition

--- abstract

This document specifies I-Regexp, a flavor of regular expressions that is
limited in scope with the goal of interoperation across many different
regular-expression libraries.

--- middle

Introduction        {#intro}
============


This specification describes an interoperable regular expression flavor, I-Regexp.

I-Regexp does not provide advanced regular expression features such as capture groups, lookahead, or backreferences.
It supports only a Boolean matching capability, i.e., testing whether a given regular expression matches a given piece of text.

I-Regexp supports the entire repertoire of Unicode characters.

I-Regexp is a subset of XSD regular expressions {{XSD-2}}.

This document includes guidance for converting I-Regexps for use with several well-known regular expression idioms.

The development of I-Regexp was motivated by the work of the JSONPath Working Group. The Working Group wanted to include
in its specification {{-jsonpath}} support for the use of regular expressions in JSONPath filters, but was unable to find a useful
specification for regular expressions which would be interoperable across the popular libraries.

## Terminology

This document uses the abbreviation "regexp" for what are usually
called regular expressions in programming.
"I-Regexp" is used as a noun meaning a character string which conforms to the requirements
in this specification; the plural is "I-Regexps".

{::boilerplate bcp14-tagged}

The grammatical rules in this document are to be interpreted as ABNF,
as described in {{-abnf}} and {{-abnf-cs}}.

# Requirements

I-Regexps should handle the vast majority of practical cases where a
matching regexp is needed in a data model specification or a query
language expression.

The editors of this document conducted a survey of the regexp syntax
used in published RFCs. All examples found there should be covered by I-Regexps,
both syntactically and with their intended semantics.
The exception is the use of multi-character escapes, for which
workaround guidance is provided in {{mapping}}.

# I-Regexp Syntax {#defn}

An I-Regexp MUST conform to the ABNF specification in
{{iregexp-abnf}}.

~~~ abnf
{::include iregexp.abnf}
~~~
{: #iregexp-abnf title="I-Regexp Syntax in ABNF"}

As an additional restriction, `charClassExpr` is not allowed to
match `[^]`, which according to this grammar would parse as a
positive character class containing the single character `^`.

This is essentially XSD regexp without character class
subtraction, without multi-character escapes such as `\s`,
`\S`, and `\w`, and without Unicode blocks.

An I-Regexp implementation MUST be a complete implementation of this
limited subset.
In particular, full Unicode support is REQUIRED; the implementation
MUST NOT limit itself to 7- or 8-bit character sets such as ASCII and
MUST support the Unicode character property set in character classes.

## Checking Implementations {#checking}

A *checking* I-Regexp implementation is one that checks a supplied
regexp for compliance with this specification and reports any problems.
Checking implementations give their users confidence that they didn't
accidentally insert non-interoperable syntax, so checking is RECOMMENDED.
Exceptions to this rule may be made for low-effort implementations
that map I-Regexp to another regexp library by simple steps such as
performing the mapping operations discussed in {{mapping}}; here, the
effort needed to do full checking may dwarf the rest of the
implementation effort.
Implementations SHOULD document whether they are checking or not.

Specifications that employ I-Regexp may want to define in which
cases their implementations can work with a non-checking I-Regexp
implementation and when full checking is needed, possibly in the
process of defining their own implementation classes.

# I-Regexp Semantics

This syntax is a subset of that of {{XSD-2}}.
Implementations which interpret I-Regexps MUST
yield Boolean results as specified in {{XSD-2}}.
(See also {{xsd-regexps}}.)

# Mapping I-Regexp to Regexp Dialects {#mapping}

The material in this section is non-normative, provided as guidance
to developers who want to use I-Regexps in the context of other
regular expression dialects.

## Multi-Character Escapes

Common multi-character escapes (MCEs), and character classes built around them,
which are not supported in I-Regexp, can usually
be replaced as shown for example in {{tbl-sub}}.

| MCE/class | Replace with     |
|-----------|------------------|
| `\S`      | `[^ \t\n\r]`     |
| `[\S ]`   | `[^\t\n\r]`      |
| `\d`      | `[0-9]`          |
{: #tbl-sub title="Example substitutes for multi-character escapes"}

Note that the semantics of `\d` in XSD regular expressions is that of
`\p{Nd}`; however, this would include all Unicode characters that are
digits in various writing systems, which is almost certainly not what is
required in IETF publications.

The construct `\p{IsBasicLatin}` is essentially a reference to legacy
ASCII, it can be replaced by the character class `[\u0000-\u007f]`.

## XSD Regexps

Any I-Regexp also is an XSD Regexp {{XSD-2}}, so the mapping is an identity
function.

Note that a few errata for {{XSD-2}} have been fixed in {{XSD11-2}}, which
is therefore also included as a normative reference.
XSD 1.1 is less widely implemented than XSD 1.0, and implementations
of XSD 1.0 are likely to include these bugfixes, so for the intents
and purposes of this specification an implementation of XSD 1.0
regexps is equivalent to an implementation of XSD 1.1 regexps.

## ECMAScript Regexps {#toESreg}

Perform the following steps on an I-Regexp to obtain an ECMAScript
regexp {{ECMA-262}}:

* For any dots (`.`) outside character classes (first alternative
  of `charClass` production): replace dot by `[^\n\r]`.
* Envelope the result in `^(?:` and `)$`.

The ECMAScript regexp is to be interpreted as a Unicode pattern ("u"
flag; see Section 21.2.2 "Pattern Semantics" of {{ECMA-262}}).

Note that where a regexp literal is required,
the actual regexp needs to be enclosed in `/`.

## PCRE, RE2, Ruby Regexps

Perform the same steps as in {{toESreg}} to obtain a valid regexp in
PCRE {{PCRE2}}, the Go programming language {{RE2}}, and the Ruby
programming language, except that the last step is:

* Enclose the regexp in `\A(?:` and `)\z`.

Motivation and Background {#background}
=========================

While regular expressions originally were intended to describe a
formal language to support a Boolean matching function, they
have been enhanced with parsing functions that support the extraction
and replacement of arbitrary portions of the matched text. With this
accretion of features, parsing regexp libraries have become
more susceptible to bugs and surprising performance degradations which
can be exploited in Denial of Service attacks by
an attacker who controls the regexp submitted for
processing. I-Regexp is designed to offer interoperability, and to be
less vulnerable to such attacks, with the trade-off that its only
function is to offer a boolean response as to whether a character
sequence is matched by a regexp.

## Implementing I-Regexp {#subsetting}

XSD regexps are relatively easy to implement or map to widely
implemented parsing regexp dialects, with these notable
exceptions:

* Character class subtraction.  This is a very useful feature in many
  specifications, but it is unfortunately mostly absent from parsing
  regexp dialects. Thus, it is omitted from I-Regexp.

* Multi-character escapes.  `\d`, `\w`, `\s` and their uppercase
  complement classes exhibit a
  large amount of variation between regexp flavors.  Thus, they are
  omitted from I-Regexp.

* Not all regexp implementations
  support accesses to Unicode tables that enable
  executing constructs such as `\p{Nd}`,
  although the `\p`/`\P` feature in general is now quite
  widely available. While in principle it’s possible to
  translate these into character-class matches, this also requires
  access to those tables. Thus, regexp libraries in severely
  constrained environments may not be able to support I-Regexp
  conformance.

IANA Considerations
==================

This document makes no requests of IANA.


Security considerations
=======================

As discussed in {{background}}, more complex regexp libraries may
contain exploitable bugs leading to crashes and remote code
execution.  There is also the problem that such libraries often have
hard-to-predict performance characteristics, leading to attacks
that overload an implementation by matching against an expensive
attacker-controlled regexp.

I-Regexps have been designed to allow implementation in a way that is
resilient to both threats; this objective needs to be addressed
throughout the implementation effort.
Non-checking implementations (see {{checking}}) are likely to expose
security limitations of any regexp engine they use, which may be less
problematic if that engine has been built with security considerations
in mind (e.g., {{RE2}}); a checking implementation is still RECOMMENDED.

--- back

Regexps and Similar Constructs in Recent Published RFCs {#rfcs}
========================================================
{:removeinrfc}

This appendix contains a number of regular expressions that have been
extracted from some recently published RFCs based on some ad-hoc matching.
Multi-line constructions were not included.
With the exception of some (often surprisingly dubious) usage of multi-character
escapes and a reference to the `IsBasicLatin` Unicode block, all
regular expressions validate against the ABNF in {{iregexp-abnf}}.

~~~
{::include iregexp.rfc.out}
~~~
{: #iregexp-examples title="Example regular expressions extracted from
RFCs"}

Acknowledgements
================
{:unnumbered}

This draft has been motivated by the discussion in the IETF JSONPATH
WG about whether to include a regexp mechanism into the JSONPath query
expression specification, as well as by previous discussions about the
YANG `pattern` and CDDL `.regexp` features.

The basic approach for this draft was inspired by {{?RFC7493 (The
I-JSON Message Format)}}.
