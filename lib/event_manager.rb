puts 'Event Manager Initialized!'

lines = File.readlines('event_attendees.csv')
lines.each_with_index do |line, index|
  next if index.zero?

  row = line.split(',')
  name = row[2]
  puts name
end
