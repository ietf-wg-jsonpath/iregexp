#!/usr/bin/env ruby

spec = ARGF.read

# ruby mabnf.rb iregexp.abnf-in | bap -k -o RFC7405 | ruby abnfbreak.rb >iregexp.abnf

def ccl1(r)
  ccl = nil
  if r[0] == r[1]
    case r[0]
    when " ", "!", "#"..."A", "["..."a", "{".."~"
      ccl = %{"#{r[0]}"}
    when "A".."Z", "a".."z"
      ccl = %{%s"#{r[0]}"}
    end
  end
  ccl ||= "%x#{"%02x" % r[0].ord}"
  ccl << "-%02x" % r[1].ord if r[0] != r[1]
  ccl
end

puts spec.gsub!(
  / (;.*) |
    "([^"]*)" |
    <<((?:[^>\\]|\\.|>[^>])+)>>([?*+]?) |
    ([^";<]*)
  /x
) {
  full, comment, string, cclass, cclassquant, chars = $~.to_a
  #warn [:MATCH, comment, string, cclass, cclassquant, chars].inspect
  if comment
    print comment
  elsif string
    # XXX need to check for \
    print "%s" if string =~ /[A-Za-z]/
    print %{"#{string}"}
  elsif cclass
    quant1, quant2 = {"?" => ["[","]"], "*" => "*", "+" => "1*"}[cclassquant]
    cclass1 = cclass.scan(/\\.|[^\\]/)
    neg = false
    if cclass1[0] == "^"
      neg = true
      cclass1.shift
    end
    bits = {}
    while cclass1 != []
      r1 = cclass1.shift
      r2, r3 = cclass1
      if r3 && r2 == "-"
        (r1..r3).each {|x| bits[x] = true}
        cclass1.shift(2)
      else
        bits[r1] = true
      end
    end
    k = bits.keys.map {|x|
      if x[0] == "\\"
        warn "** x2 #{x}" if x.size != 2
        x[1]
      else
        warn "** x1 #{x}" if x.size != 1
        x[0]
      end
    }.sort
    r = []
    k.each do |kk|
      if r[-1] && r[-1].succ == kk
        r[-1] = kk
      else
        r << kk
        r << kk
      end
    end
    if neg
      last = "\x00"
      cmpl = []
      r.each_slice(2) {|le, ri|
        if (le != last)
          cmpl << last
          cmpl << (le.ord - 1).chr(Encoding::UTF_8)
        end
        last = ri.succ
      }
      cmpl << last
      cmpl << 0x10FFFF.chr(Encoding::UTF_8)
      r = cmpl
    end
    r = r.each_slice(2).flat_map {|l, r|
      if r.ord == l.ord + 1             # Martin Dürst's comment
        [l, l, r, r]
      else
        [l, r]
      end
    }
    if r.size == 2
      ccl = ccl1(r)
    else
      ccl = "(#{r.each_slice(2).map {|x| ccl1(x)}.join(" / ") })"
    end
    print "#{quant1}#{ccl}#{quant2}"
  elsif chars
    print chars
  else
    warn "**huh #{full}"
  end
}
