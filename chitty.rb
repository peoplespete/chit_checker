require 'securerandom'
require 'csv'
require 'pry'
require 'colorize'

def print_chits(chits)
  puts "Date       |Amount| Description".light_magenta.on_blue.bold
  chits.sort_by { |c| c[:date] }.each do |chit|
    puts "#{chit[:date]} ".blue.on_light_yellow + " $#{sprintf( "%0.02f", chit[:amount].round(2))} ".blue.on_light_white + " #{chit[:description]}".blue.on_light_magenta
  end
end

def generic_ask(name, items)
  puts "Which one is #{name}?".blue.on_yellow
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

def get_allegacy_chits(allegacy_filename)
  started = false
  last_row = ''
  chits = []
  income = []
  CSV.foreach("../../Downloads/#{allegacy_filename}") do |row|
    started = true if last_row == 'Transaction Number'
    last_row = row[0]
    next unless started
    description = "#{row[2]} + #{row[3]}"
    description = description[0..-12]  if description[/.+NBR\:/]
    is_chit = !!row[4]
    amount = is_chit ? (row[4].to_f * -1) : row[5].to_f

    chit = {
      uuid: SecureRandom.base64,
      date:  Date.strptime(row[1], "%m/%d/%Y"),
      amount: amount,
      description: description
    }
    if chit[:amount] > 0 && !chit[:description].include?("TRANSFER TO CK")

      if is_chit
        chits.push chit
      else
        income.push chit
      end
    end
  end
  [income, chits]
end

def get_capital_one_chits(capital_one_filename)
  chits = []
  income = []

  CSV.foreach("../../Downloads/#{capital_one_filename}") do |row|
    next if row[0] == 'Stage'
    chit = {
      uuid: SecureRandom.base64,
      date:  Date.strptime(row[1], "%m/%d/%Y"),
      description: row[4]
    }
    chit[:amount] = row[6].to_f
    if chit[:amount] > 0
      chits.push chit
    else
      chit[:amount] = row[7].to_f
      income.push chit
    end
  end
  [income, chits]
end

allegacy_filename = generic_ask('Allegacy', Dir.entries('../../Downloads/').select { |f| f[/\.csv/] })
capital_one_filename = generic_ask('Capital One', Dir.entries('../../Downloads/').select { |f| f[/\.csv/] })

chits = []
incomes = []

allegacy_incomes, allegacy_chits = get_allegacy_chits(allegacy_filename)
chits.push *allegacy_chits
incomes.push *allegacy_incomes


capital_one_incomes, capital_one_chits = get_capital_one_chits(capital_one_filename)
chits.push *capital_one_chits
incomes.push *capital_one_incomes

chits = chits.sort_by{ |chit| chit[:date] }
incomes = incomes.sort_by{ |income| income[:date] }

loop do
  mode = generic_ask('mode',['Chit', 'Income'])
  case mode

  when 'Chit'
    print_chits(chits)
    loop do
      puts "What is your amount? (or enter to choose mode)".bold.green
      response = STDIN.gets.chomp
      break if response == ''
      amt = response.to_f
      matchers = chits.select{ |c| c[:amount] == amt }
      if matchers.size == 1
        matcher = matchers.first
        chits.delete(matcher)
        message = "Removed #{matcher[:description]} on #{matcher[:date]}.".bold.green
      elsif matchers.size > 1
        matcher = ask(matchers)
        chits.delete(matcher)
        message = "Removed #{matcher[:description]} on #{matcher[:date]}.".bold.green
      else
        message = "There was some problem finding #{amt}.".red.on_yellow
      end
      print_chits(chits)
      puts message
    end

  when 'Income'
    print_chits(incomes)
    loop do
      puts "What is your amount? (or enter to choose mode)".bold.green
      response = STDIN.gets.chomp
      break if response == ''
      amt = response.to_f
      matchers = incomes.select{ |c| c[:amount] == amt }
      if matchers.size == 1
        matcher = matchers.first
        incomes.delete(matcher)
        message = "Removed #{matcher[:description]} on #{matcher[:date]}.".bold.green
      elsif matchers.size > 1
        matcher = ask(matchers)
        incomes.delete(matcher)
        message = "Removed #{matcher[:description]} on #{matcher[:date]}.".bold.green
      else
        message = "There was some problem finding #{amt}.".red.on_yellow
      end
      print_chits(incomes)
      puts message
    end

  end

end


