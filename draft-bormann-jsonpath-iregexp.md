---
title: >
  I-Regexp: An Interoperable Regexp Format
abbrev: I-Regexp
docname: draft-bormann-jsonpath-iregexp-latest
date: 2022-01-18

stand_alone: true

ipr: trust200902
keyword: Internet-Draft
cat: std
consensus: true

pi: [toc, sortrefs, symrefs, compact, comments]

venue:
  mail: JSONpath@ietf.org
  github: cabo/iregexp

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
    email: tbray@textuality.com

normative:
  XSD-2: W3C.REC-xmlschema-2-20041028
  XSD11-2: W3C.REC-xmlschema11-2-20120405

informative:
  RFC8610: cddl
  RFC7950: yang
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
#  cddlc:
#    title: CDDL conversion utilities
#    target: https://github.com/cabo/cddlc
#  jsonpath:
#    target: https://jsonpath.com
#    title: jsonpath online evaluator
  REGEX-CVE:
    target: "https://cve.mitre.org/cgi-bin/cvekey.cgi?keyword=regex"
    title: >
      CVE - Search Results

--- abstract

This document specifies I-Regexp, a flavor of regular expressions that is
limited in scope with the goal of interoperation across many different
regular-expression libraries.

--- middle

Introduction        {#intro}
============


The present specification defines an interoperable regular expression flavor, I-Regexp.

This document uses the abbreviation "regexp" for what are usually
called regular expressions in programming.
"I-Regexp" is used as a noun meaning a character string which conforms to the requirements
in this specification; the plural is "I-Regexps".

I-Regexp does not provide advanced regexp features such as capture groups, lookahead, or backreferences.
It supports only a Boolean matching capability, i.e. testing whether a given regexp matches a given piece of text.

I-Regexp is a subset of XSD regexps {{XSD-2}}.

This document includes rules for converting I-Regexps for use with several well-known regexp libraries.

## Terminology

{::boilerplate bcp14-tagged}

# Requirements

I-Regexps should handle the vast majority of practical cases where a
matching regexp is needed in a data model specification or a query
language expression.

A brief survey of published RFCs yielded the regexp patterns in
Appendix A (with no attempt at completeness).
With certain exceptions as discussed there,
these should be covered by I-Regexps, both syntactically and with
their intended semantics.

# I-Regexp Syntax {#defn}

An I-Regexp MUST conform to the ABNF specification in
{{iregexp-abnf}}.

~~~ abnf
{::include iregexp.abnf}
~~~
{: #iregexp-abnf title="I-Regexp Syntax in ABNF"}

This is essentially XSD regexp without character class
subtraction and multi-character escapes.

* **Issues**: There might be further potential for simplification in IsBlock (leave
  out) and possibly in the rather large part for IsCategory as well.
  The ABNF has been automatically generated and maybe could use some
  polishing.
  The ABNF has been verified against {{rfcs}}, but a wider corpus of
  regular expressions should be examined.
  About a third of the complexity of this ABNF grammar comes from going
  into details on the Unicode IsCategory classes.  Additional complexity
  stems from the way hyphens can be used inside character classes to denote
  ranges; the grammar deliberately excludes questionable usage such as
  `/[a-z-A-Z]/`.


# I-Regexp Semantics

This syntax is a subset of that of {{XSD-2}}.
Implementations which interpret I-Regexps MUST
yield Boolean results as specified in {{XSD-2}}.
(See also {{xsd-regexps}}.)

# Mapping I-Regexp to Regexp Dialects

(TBD; these mappings need to be thoroughly verified.)

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

* Replace any dots (`.`) outside character classes (first alternative
  of `charClass` production) by `[^\n\r]`.
* Envelope the result in `^` and `$`.

Note that where a regexp literal is required, this needs to enclose
the actual regexp in `/`.

The performance can be increased by turning parenthesized regexps
(production `atom`) into `(?:...)` constructions.

## PCRE, RE2, Ruby Regexps

Perform the same steps as in {{toESreg}} to obtain a valid regexp in
PCRE {{PCRE2}}, the Go programming language {{RE2}}, and the Ruby
programming language, except that the last step is:

* Envelope the result in `\A` and `\z`.

Again, the performance can be increased by turning parenthesized
regexps (production `atom`) into `(?:...)` constructions.

## << Your kind of Regexp here >>

(Please submit the mapping needed for your favorite kind of regexp.)

Motivation and Background {#background}
=========================

Data modeling formats (YANG, CDDL) as well as query languages
(jsonpath) often need a regular expression (regexp) sublanguage.
There are many dialects of regular expressions in use in platforms,
programming languages, and data modeling formats.

While regular expressions originally were intended to provide a
Boolean matching function, they have turned into parsing functions for
many applications, with capture groups, greedy/lazy/possessive variants, etc.
Language features such as backreferences allow specifying languages
that actually are context-free (Chomsky type 2) instead of the regular
languages (Chomsky type 3) that regular expressions are named for.

YANG ({{Section 9.4.5 of -yang}}) and CDDL ({{Section 3.8.3 of
-cddl}}) have adopted the regexp language from W3C Schema {{XSD-2}}.
XSD regexp is a pure matching language, i.e., XSD regexps can be used
to match a string against them and yield a simple true or false
result.
XSD regexps are not as widely implemented as programming language
regexp dialects such as those of Perl, Python, Ruby, Go {{RE2}}, or
JavaScript (ECMAScript) {{ECMA-262}}.
The latter are often in a state of continuous development; in the best
case (ECMAScript) there is a complete specification which however is
highly complex (Section 21.2 of {{ECMA-262}} comprises 62 pages) and
evolves on a yearly timeline, with significant additions.
Regexp dialects such as PCRE {{PCRE2}} have evolved to cover a
common set of functions available in parsing regexp dialects, offered
in a widely available library.

With continuing accretion of complex features, parsing regexp
libraries have become susceptible to bugs and performance degradation,
in particular those that can be exploited in Denial of Service (DoS) attacks.
The library RE2 that is compatible with Go language regexps strives to
be immune to DoS attacks, making it attractive to applications such as
query languages where an attacker could control the input.
The problem remains that other bugs in such libraries can lead to
exploitable vulnerabilities; at the time of writing, the Common
Vulnerabilities and Exposures (CVE) system has 131 entries that
mention the word "regex" {{REGEX-CVE}} (not all, but many of which are
such bugs, with 23 matches for arbitrary code execution).

Implementations of YANG and CDDL often struggle with providing true
XSD regexps; some instead cheat by providing one of the parsing regexp
varieties, sometime without even advertising this fact.

A matching regexp that does not use the more complex XSD features
({{subsetting}}) can usually be converted into a parsing regexp of many
dialects by simply surrounding it with anchors of that dialect (e.g., `^` or `\A` and `$` or `\z`).
If the original matching regexps exceed the envelope of compatibility
between dialects, this can lead to interoperability problems, or,
worse, security vulnerabilities.
Also, features of the target dialect such as capture groups may be triggered inadvertently, reducing performance.


## Subsetting XSD Regexps {#subsetting}

XSD regexps are relatively easy to implement or map to widely
implemented parsing regexp dialects, with a small number of notable
exceptions:

* Character class subtraction.  This is a very useful feature in many
  specifications, but it is unfortunately mostly absent from parsing
  regexp dialects.

  * **Issue**: This absence can often be addressed by translating
    character class subtraction into positive character classes
    (possibly requiring significant expansion) and/or inserting
    negative lookahead assertions (which are not universally supported
    by regexp libraries, most notably not by RE2 {{RE2}}).
    This specification therefore opts for leaving out character class
    subtraction.

* Multi-character escapes.  `\d`, `\w`, `\s` and their uppercase
  equivalents (complement classes) exhibit a
  large amount of variation between regexp flavors.
  (E.g., predefined character classes such as `\w` may be meant
  to be ASCII only, or they may encompass all letters and digits
  defined in Unicode.    The latter is usually of interest in query
  languages, while the former is of interest to a subset of
  applications in data model specifications.)

* Unicode.
  While there is no doubt that a regexp flavor meant to last needs to
  be Unicode enabled, there are a number of aspects of this that need
  discussion.
  Not all regexp implementations that one might want to map
  I-Regexps to will support accesses to Unicode tables that enable
  executing on constructs such as `\p{IsCoptic}`.
  Fortunately, the `\p`/`\P` feature in general is now quite
  widely available.

  * **Issue**: The ASCII focus can partially be addressed by adding a
    constraint that the matched text has to be ASCII in the first
    place.  This often is all that is needed where regexps are used to
    define lexical elements of a computer language.  The access to
    Unicode tables can simply be ruled out.  (Note that RFC 6643
    contains a lone instance of `\p{IsBasicLatin}{0,255}`, which is
    needed to describe a transition from a legacy character set to
    Unicode.  The author believes that this would be a rare
    application and can be left out.  RFC2622 contains `[[:digit:]]`,
    `[[:alpha:]]`, `[[:alnum:]]`, albeit in a  specification for the
    `flex` tool; this is intended to be close to `\d`, `\p{L}`, `\w`
    in an ASCII subset.)


IANA Considerations
==================

This document makes no requests of IANA.


Security considerations
=======================

TBD

(Discuss security issues of regexp implementations, both DoS and RCE;
this is covered in part in {{background}}.)

--- back

Regexps and Similar Constructs in Recent Published RFCs {#rfcs}
========================================================

This appendix contains a number of regular expressions that have been
extracted from some recently published RFCs based on some ad-hoc matching.
Multi-line constructions were not included.
With the exception of some (often surprisingly dubious) usage of multi-character
escapes, all regular expressions validate against the ABNF in {{iregexp-abnf}}.

~~~
{::include iregexp.rfc.out}
~~~
{: #iregexp-examples title="Example regular expressions extracted from
RFCs"}

Acknowledgements
================
{: numbered="no"}

This draft has been motivated by the discussion in the IETF JSONPATH
WG about whether to include a regexp mechanism into the JSONPath query
expression specification, as well as by previous discussions about the
YANG `pattern` and CDDL `.regexp` features.

The basic approach for this draft was inspired by {{?RFC7493 (The
I-JSON Message Format)}}.
