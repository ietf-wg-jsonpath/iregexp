require 'shellwords'

# Requires a recent bap; install from https://github.com/fenner/bap

task :default => ['iregexp.v2v3.xml']

file 'iregexp.abnf' => ['iregexp.abnf-in', 'mabnf.rb', 'abnfbreak.rb'] do |t|
  # -o RFC7405: allow %s"case-sensitive-string"
  # -k: add comments about hex char ranges
  sh %{ruby mabnf.rb iregexp.abnf-in | bap -k -o RFC7405 | ruby abnfbreak.rb >iregexp.abnf}
end

file 'iregexp.rfc.out' => ['rfc-pattern3'] do |t|
  sh %{ruby check-pattern.rb rfc-pattern3 >iregexp.rfc.out}
end

file 'iregexp.v2v3.xml' => ['iregexp.md', 'iregexp.rfc.out', 'iregexp.abnf']

rule '.v2v3.xml' => ['.md'] do |t|
  sh %(kdrfc -3chi #{t.source})
  # sh %(open #{t.name})
end
