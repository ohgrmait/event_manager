require 'csv'
require 'google-apis-civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = File.read('secret.key').strip

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    )
    legislators.officials
  rescue StandardError
    'You can find your representatives by visiting ' \
    'www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_homephone(homephone)
  phone = homephone.gsub(/\D/, '')
  if phone.length == 10
    homephone
  elsif phone.length == 11 && phone[0] == '1'
    homephone.slice(1..)
  else
    'Invalid'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

timings = {}

def peak_registration_hours(timings, reg_time)
  time = Time.strptime(reg_time, '%k:%M')
  if timings.key?(time.hour)
    timings[time.hour] += 1
  else
    timings[time.hour] = 1
  end
end

registrations = {}

def most_people_registered(registrations, reg_date)
  date = Date.strptime(reg_date, '%m/%d/%Y')
  if registrations.key?(date.strftime('%A'))
    registrations[date.strftime('%A')] += 1
  else
    registrations[date.strftime('%A')] = 1
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]

  name = row[:first_name]

  phone = clean_homephone(row[:homephone])

  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  reg_time = row[:regdate].split[1]
  reg_date = row[:regdate].split[0]
  peak_registration_hours(timings, reg_time)
  most_people_registered(registrations, reg_date)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

peak_hours = timings.select { |time, count| count == timings.values.max }
puts "Peak Registration Hours = #{peak_hours.keys.join(', ')}"

most_days = registrations.select { |registration, count| count == registrations.values.max }
puts "Most Days of the Week Registered = #{most_days.keys.join(', ')}"
