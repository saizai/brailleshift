#!/usr/bin/env ruby

$dict = File.read("/usr/share/dict/words").split("\n")

$braille = { 'a' => '100000', 'b' => '110000', 'c' => '100100', 'd' => '100110', 'e' => '100010', 'f' => '110100', 'g' => '110110', 'h' => '110010', 'i' => '010100', 'j' => '010110', 'k' => '101000', 'l' => '111000', 'm' => '101100', 'n' => '101110', 'o' => '101010', 'p' => '111100', 'q' => '111110', 'r' => '111010', 's' => '011100', 't' => '011110', 'u' => '101001', 'v' => '111001', 'w' => '010111', 'x' => '101101', 'y' => '101111', 'z' => '101011', '^' => '000001', '#' => '001111', "'" => '001000', '.' => '010011', ',' => '010000', ';' => '011000', '!' => '011010', '`' => '011001', '"' => '001011', '(' => '011011', '-' => '001001', ':' => '010010'}

def munge word, letter
  pattern = (0..5).map{|x| $braille[letter][x] == '1' ? x : nil} - [nil]
  done = Array.new(pattern.length, false)
  i = -1
  ret = word.split('').map do |l|
    caps = (l.capitalize == l)
    l.downcase!
    ll = '?'
    until ll != '?' 
      i += 1
      ll = neighbors(l, true)[pattern[i % pattern.length]]
    end
    done[i % pattern.length] = true
    caps ? ll.capitalize : ll
  end
  done.include?(false) ? '---' : ret.join
end

def munge_phrase phrase, word
  i = -1
  phrase.split(' ').map do |word_to_munge|
    i += 1
    munge word_to_munge, word[i]
  end.join(' ')
end

def neighbors letter, padded = false
  letter.downcase!
  rows = [%w(1 2 3 4 5 6 7 8 9 0 - =),
    %w(q w e r t y u i o p [ ]),
    %w(a s d f g h j k l ; '),
    %w(z x c v b n m , . /)]

  row = rows.map{|r| r.index letter}.index{|r| !r.nil?}
  col = rows.map{|r| r.index letter}[row]
  ret = ''
  ret << ((row > 0) ? rows[row - 1][col] : '?')
  ret << ((col > 0) ? rows[row][col - 1] : '?')
  ret << ((row < 3 and col > 0) ? rows[row + 1][col - 1] : '?')
  ret << ((row > 0 and (rows[row-1].size > (col + 1))) ? rows[row - 1][col + 1] : '?')
  ret << ((rows[row].size > (col + 1)) ? rows[row][col + 1] : '?')
  ret << ((row < 3 and rows[row+1].size > (col)) ? rows[row + 1][col] : '?')
  
  ret.gsub!('?','') unless padded
  ret
end

def find_neighbors text
  text = text.gsub(' ', '').downcase.split('').map{|letter| '[' + Regexp.escape(neighbors(letter)) + ']'}.join
  r = Regexp.new('^' + text + '$', true) # true = case insensitive
  $dict.grep r
end

def name_offset original, shifted
  dots = [];
  original.downcase.gsub(' ','').split('').each_with_index do |letter, i| 
    dots << neighbors(letter, true).index(shifted[i].downcase)
  end
  pattern = (0..5).map{|i| dots.include?(i) ? '1' : '0'}.join
  $braille.rassoc(pattern)[0] rescue pattern
end

def findall
  ret = []
  begin
    require 'csv'
    out = CSV.open('results.txt', 'a')
    $dict.each do |word| 
      newret = find_neighbors(word).map{|x| [word, x, name_offset(word, x)]}
      newret.each {|r| out << r; ret << r }
    end
  ensure
    out.close
  end
  ret
end

$counts = {}
def load_counts
  # require 'csv'
  # CSV.foreach('1grams.csv', :col_sep => "\t") do |row|
  File.open '1grams.csv', 'r' do |csvfile|
    while line = csvfile.first
      row = line.split
      $counts[row[0]] = row[1].to_i
    end
  end
end

def count
  ret = []
  # require 'csv'
  # CSV.foreach('results.txt') do |row|
  File.open 'results.txt', 'r' do |rfile|
    while line = rfile.first
      row = line.strip.split ','
      if row[2] =~ /[a-z]/
        ret << [row[1], $counts[row[1]]] 
      end
    end
  end
  ret.uniq!
  ret.sort!{|a,b| (b[1]||0) <=> (a[1]||0)}
  ret.map!{|x|x[0]}
  ret.select{|x| x.size > 3}[0..500].sort.join(' ')
end

findall