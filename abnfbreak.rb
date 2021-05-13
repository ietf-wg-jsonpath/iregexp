#!/usr/bin/env ruby

li = ARGF.read.lines

li.each do |*l|
  while l[-1].size > 69
    breakpoint = l[-1][0...69].rindex(' ')
    break unless breakpoint && breakpoint > 4
    l[-1..-1] = [
      l[-1][0...breakpoint],
      "    " << l[-1][breakpoint+1..-1]
    ]
  end
  puts l
end
