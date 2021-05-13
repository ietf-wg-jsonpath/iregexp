require 'abnftt'

# ruby check-pattern.rb rfc-pattern3 >iregexp.rfc.out

patterns = ARGF.read.lines

grammar = File.read("iregexp.abnf")
parser = ABNF.from_abnf(grammar)

#          out = parser.generate

current_file = nil
patterns.each do |pat|
  case pat
  when /^File: (.*)$/
    current_file = $1
  when /^(\d+):\d+:\s+pattern (["'])(.*)\2/
    current_line = $1
    patcont = $3
    # p [:GOOD, current_file, current_line, patcont]
    begin
      parser.validate(patcont)
      puts "#{current_file} #{"%4d" % current_line} #{patcont}"
    rescue StandardError => e
      # p e
      puts e.message
    end
  else
    p [:FILE, current_file, pat]
  end
  
end



