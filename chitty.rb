# require 'Date'
require 'csv'
require 'pry'
require 'colorize'

p String.colors
def print_chits(chits)
  puts "Date       |Amount| Description".light_magenta.on_blue.bold
  chits.sort_by { |c| c[:date] }.each do |chit|
    puts "#{chit[:date]} ".blue.on_light_yellow + " $#{sprintf( "%0.02f", chit[:amount].round(2))} ".blue.on_light_white + " #{chit[:description]}".blue.on_light_magenta
  end
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
CSV.foreach("Export.csv") do |row|
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
  chits.push chit if chit[:amount] > 0
end

loop do
  print_chits(chits)
  puts "What is your amount?".bold.green
  amt = STDIN.gets.chomp.to_f
  matchers = chits.select{ |c| c[:amount] == amt }
  if matchers.size == 1
    matcher = matchers.first
    chits.delete(matcher)
    puts "Removed #{matcher[:description]} on #{matcher[:date]}.".bold.green
  elsif matchers.size > 1
    matcher = ask(matchers)
    chits.delete(matcher)
    puts "Removed #{matcher[:description]} on #{matcher[:date]}.".bold.green
  else
    puts "There was some problem finding #{amt}.".red.on_yellow
  end
end

