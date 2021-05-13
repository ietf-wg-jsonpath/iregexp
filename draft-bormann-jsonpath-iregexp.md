---
title: >
  I-Regexp: An Interoperable Regexp Format
abbrev: I-Regexp
docname: draft-bormann-jsonpath-iregexp-latest
date: 2021-05-13

stand_alone: true

ipr: trust200902
keyword: Internet-Draft
cat: std
consensus: true

pi: [toc, sortrefs, symrefs, compact, comments]

author:
  -
    ins: C. Bormann
    name: Carsten Bormann
    org: Universität Bremen TZI
    street: Postfach 330440
    city: Bremen
    code: D-28359
    country: Germany
    phone: +49-421-218-63921
    email: cabo@tzi.org


normative:
  XSD2: W3C.REC-xmlschema-2-20041028

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

"Regular expressions" (regexps) are a set of related, widely
implemented pattern languages used in data modeling formats and query
languages that is available in many dialects.
This specification defines an interoperable flavor of regexps, I-Regexp.

The present version -00 of this document is a trial balloon, meant to
determine whether this approach is useful for the JSONPath WG.

--- middle

Introduction        {#intro}
============

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
-cddl}}) have adopted the regexp language from W3C Schema {{XSD2}}.
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
libraries have become susceptible to bugs, in particular those that
can be exploited in DoS attacks.
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

A matching regexp that does not use the more complex XSD features ({{subsetting}}) can usually be converted into a parsing regexp of many dialects by surrounding it with anchors of that dialect (e.g., `^` or `\A` and `$` or `\z`).
If the original matching regexps exceed the envelope of compatibility
between dialects, this can lead to interoperability problems, or,
worse, security vulnerabilities.
Also, features of the target dialect such as capture groups may be triggered inadvertently, reducing performance.

The present specification defines an interoperable regexp flavor for matching, I-Regexp.
This flavor is a subset of XSD regexps.  It also comes with defined rules for converting the regexp into common parsing regexp dialects.

# Requirements

I-Regexps should handle the vast majority of practical cases where a
matching regexp is needed in a data model specification or a query
language expression.

A brief survey of published RFCs yielded the regexp patterns in
Appendix A (with no attempt at completeness).
These should be covered by I-Regexps, both syntactically and with
their intended semantics.

# Subsetting XSD Regexps {#subsetting}

XSD Regexps are relatively easy to implement or map to widely
implemented parsing regexp dialects, with a small number of notable
exceptions:

* Character class subtraction.  This is a very useful feature in many
  specifications, but it is unfortunately mostly absent from parsing
  regexp dialects.

  * **Issue**: This absence can be addressed by translating character
    class subtraction into positive character classes, or by leaving
    out subtraction.  The current draft opts for the latter, but that
    decision is up for discussion.

* Unicode.
  While there is no doubt that a regexp flavor meant to last needs to
  be Unicode enabled, there are a number of aspects of this that need
  discussion.
  First of all, predefined character classes such as `\w` may be meant
  to be ASCII only, or they may encompass all letters and digits
  defined in Unicode.
  The latter is usually of interest in query languages, while the
  former is of interest to a subset of applications in data model
  specifications.
  Second, not all regexp implementations that one might want to map
  I-Regexps to will support accesses to Unicode tables that enable
  executing on constructs such as `\p{IsCoptic}`.

  * **Issue**: The ASCII focus can partially be addressed by adding a
    constraint that the matched text has to be ASCII in the first
    place.  This often is all that is needed where regexps are used to
    define lexical elements of a computer language.  The access to
    Unicode tables can simply be ruled out.  (Note that RFC 6643
    contains a lone instance of `\p{IsBasicLatin}{0,255}`, which is
    needed to describe a transition from a legacy character set to
    Unicode.  The author believes that this would be a rare
    application and can be left out.  RFC2622 contans `[[:digit:]]`,
    `[[:alpha:]]`, `[[:alnum:]]`, albeit in a  specification for the
    `flex` tool; this is intended to be close to `\d`, `\p{L}`, `\w`
    in an ASCII subset.)

# Formal definition of I-Regexp

The syntax of I-Regexp is defined by the ABNF specification in
{{iregexp-abnf}}.
This syntax is a subset of that of {{XSD2}};
the semantics of all the constructs allowed by this ABNF are the same as those in {{XSD2}}.

~~~ ABNF
{::include iregexp.abnf}
~~~
{: #iregexp-abnf}

* **Issue**: This is essentially XSD regexp without character class
  subtraction.
  There is probably potential for simplification in IsBlock (leave
  out) and possibly in the rather large part for IsCategory as well.
  The ABNF has been automatically generated and maybe could use some
  polishing.
  The ABNF has been verified against {{rfcs}}, but a wider corpus of
  regular expressions should be examined.

# Mapping I-Regexp to Regexp Dialects

(TBD; these mappings need to be thoroughly verified.)

## XSD Regexps

Any I-Regexp also is an XSD Regexp {{XSD2}}, so the mapping is an identify
function.

## ECMAScript Regexps

An I-Regexp, enveloped in `^` and `$`, is an ECMAScript regexp
{{ECMA-262}}.
The performance can be increased by turning parenthesized regexps
(production `atom`) into `(?:...)` constructions.

## PCRE, RE2, Ruby Regexps

An I-Regexp, enveloped in `\A` and `\z`, is a valid regexp in PCRE
{{PCRE2}}, the Go programming language {{RE2}}, and the Ruby programming language.
The performance can be increased by turning parenthesized regexps
(production `atom`) into `(?:...)` constructions.

## << Your kind of Regexp here >>

(Please submit the mapping needed for your favorite kind of regexp.)

IANA Considerations
==================

This document makes no requests of IANA.


Security considerations
=======================

TBD

(Discuss security issues of regexp implementations, both DoS and RCE;
this is covered in part in {{intro}}.)

--- back

Regexps and Similar Constructs in Published RFCs {#rfcs}
================================================

This appendix contains a number of regular expressions that have been
extracted from published RFCs based on some ad-hoc matching.
Multi-line constructions were not included.
All regular expressions validate against the ABNF in {{iregexp-abnf}}.

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
