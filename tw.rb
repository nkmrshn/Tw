#!/usr/bin/env ruby
require 'lib/tw'

def prompt(string)
  print string.gsub('_', ' ').capitalize + ":"
  gets.strip
end

status = ''
filename = nil

tw = Tw.new

begin
  tw.load_config
rescue
  Tw::CONFIG.each {|c| tw.instance_variable_set("@#{c.downcase}", prompt(c)) }

  begin
    tw.save_config
    puts "saved to #{tw.config_file}"
  rescue
    puts "failed to save."
  end
end

ARGV.each_with_index do |argv, idx|
  if tw.valid_extension?(argv) && idx == ARGV.length - 1
    filename = argv
    break
  end

  status += ' ' unless status.empty?
  status += tw.shorten_if_url(argv)
end

puts Net::HTTPOK === tw.post(status, filename) ? 'posted.' : 'failed.' unless status.empty?
