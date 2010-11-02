#!/usr/bin/ruby

# This script is part of SEIA Data, A set of tools to manage
# information in http://www.e-seia.cl, a chilean goverment web site.
#
# SEIA Data is copyrighted free software by Daniel Hernandez
# (http://www.molinoverde.cl): you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# SEIA Data is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with SEIA Data. If not, see <http://www.gnu.org/licenses/>.

# TODO: Description of that this script do.

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
  # Endpoint uri
  options[:endpoint] = nil
  opts.on('-e', '--endpoint ENDPOINT', 'Endpoint uri') do |endpoint|
    options[:endpoint] = endpoint
  end
  # Endpoint key
  options[:key] = nil
  opts.on('-k', '--key KEY', 'Endpoint key') do |key|
    options[:key] = key
  end
  # Help screen
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

Dir["#{options[:directory]}/#{options[:prefix]}*.sparql"].sort.each do |file|
  puts "sending #{file}"
  query = File.new(file).read
  RestClient.post(options[:endpoint], :query => query, :key => options[:key], :output => 'jason') do |res|
    p res
  end
end
