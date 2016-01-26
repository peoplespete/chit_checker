# require 'Date'
require 'csv'
require 'pry'
require 'colorize'

def print_chits(chits)
  puts "Date       |Amount| Description".light_magenta.on_blue.bold
  chits.sort_by { |c| c[:date] }.each do |chit|
    puts "#{chit[:date]} ".blue.on_light_yellow + " $#{sprintf( "%0.02f", chit[:amount].round(2))} ".blue.on_light_white + " #{chit[:description]}".blue.on_light_magenta
  end
end

def generic_ask(items)
  puts "Which one is it?".blue.on_yellow
  items.each.with_index do |item, i|
    puts "#{i+1}) #{item} ".blue.on_light_yellow
  end
  num = STDIN.gets.chomp.to_i rescue nil
  return nil if num.nil?
  items[num-1]
end

def ask(chits)
  puts "Which one is it?".blue.on_yellow
  chits.each.with_index do |chit, i|
    puts "#{i+1}) #{chit[:date]} ".blue.on_light_yellow + " $#{sprintf( "%0.02f", chit[:amount].round(2))} ".blue.on_light_white + " #{chit[:description]}".blue.on_light_magenta
  end
  num = STDIN.gets.chomp.to_i rescue nil
  return nil if num.nil?
  chits[num-1]
end

started = false
last_row = ''
chits = []
filename = generic_ask(Dir.entries('../../Downloads/').select { |f| f[/\.csv/] })

CSV.foreach("../../Downloads/#{filename}") do |row|
  started = true if last_row == 'Transaction Number'
  last_row = row[0]
  next unless started
  description = "#{row[2]} + #{row[3]}"
  description = description[0..-12]  if description[/.+NBR\:/]

  chit = {
    date:  Date.strptime(row[1], "%m/%d/%Y"),
    amount: row[4].to_f * -1,
    description: description
  }
  chits.push chit if chit[:amount] > 0 && !chit[:description].include?("TRANSFER TO CK")
end

print_chits(chits)
loop do
  puts "What is your amount?".bold.green
  amt = STDIN.gets.chomp.to_f
  matchers = chits.select{ |c| c[:amount] == amt }
  if matchers.size == 1
    matcher = matchers.first
    chits.delete(matcher)
    chits.slice!(chits.index(matcher))
    message = "Removed #{matcher[:description]} on #{matcher[:date]}.".bold.green
  elsif matchers.size > 1
    matcher = ask(matchers)
    chits.slice!(chits.index(matcher))
    message = "Removed #{matcher[:description]} on #{matcher[:date]}.".bold.green
  else
    message = "There was some problem finding #{amt}.".red.on_yellow
  end
  print_chits(chits)
  puts message
end

