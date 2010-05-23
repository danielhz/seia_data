require 'rubygems'
require 'rest_client'
require 'optparse'

# This hash will store options parsed from ARGV.
options = {}

optparse = OptionParser.new do |opts|
  # Usage banner displayed on top of the help screen.
  opts.banner = "Usage: lib/upload_triples.rb [options] server keyfile"
  # Directory
  options[:directory] = 'data'
  opts.on('-d', '--directory DIRECTORY', 'Directory of sparql queries') do |dir|
    options[:directory] = dir
  end
  # File prefix
  options[:prefix] = 'list-page-'
  opts.on('-p', '--prefix PREFIX', 'File prefix of sparql queries') do |prefix|
    options[:prefix] = prefix
  end
  # Help screen
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

unless ARGV.size == 2
  puts opts
  raise
end

Dir["#{options[:directory]}/#{options[:prefix]}*.sparql"].sort.each do |file|
  puts "sending #{file}"
  query = File.new(file).read
  RestClient.post(ARGV[0], :query => query, :key => ARGV[1], :output => 'jason') do |res|
    p res
  end
end
