#!/usr/bin/ruby

# This file is part of SEIA Data.
#
# RubyPiche is copyrighted free software by Daniel Hernandez
# (http://www.molinoverde.cl): you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# RubyPiche is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with RubyPiche. If not, see <http://www.gnu.org/licenses/>.

# Requirements:
# - Ruby hpricot gem
#
# This file create a YAML file for each downloaded HTML page of seia
# proyects list.
#
# USAGE:
# ruby lib/list_to_yaml.rb [options]
#
# For help use:
# ruby lib/list_to_yaml.rb --help

require 'rubygems'
require 'hpricot'
require 'optparse'

# This hash will store options parsed from ARGV.
options = {}

optparse = OptionParser.new do |opts|
  # Usage banner displayed on top of the help screen.
  opts.banner = "Usage: lib/list_to_yaml.rb [options]"
  # Directory
  options[:directory] = 'data'
  opts.on('-d', '--directory', 'Directory of downloaded pages') do |dir|
    options[:directory] = dir
  end
  # File prefix
  options[:prefix] = 'list-page-'
  opts.on('-p', '--prefix', 'File prefix for downloaded pages') do |prefix|
    options[:prefix] = prefix
  end
  # Help screen
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

Dir["#{options[:directory]}/#{options[:prefix]}*.html"].sort.each do |file|
  output = File.new(file.sub(/.html$/, '.yaml'), 'w')
  output << "---\n"
  puts "parsing #{file}"
  doc = open(file) { |f| Hpricot(f) }
  # Parse items in the list
  (doc/"//table[@class='tabla_datos']/tbody/tr").each do |tr|
    t = (tr/"td").map
    project = {}

    if (t[1]/"a").empty?
      puts t[1].inspect
    else
      project[:uri] = (t[1]/"a").first.attributes['href']
    end
    project[:id] = project[:uri].clone()
    project[:id].sub!('https://www.e-seia.cl/expediente/expediente.php?id_expediente=', '')
    project[:id].sub!('&modo=ficha', '')
    project[:title] = (t[1]/"a").inner_html.strip.gsub('"', '\"')
    project[:type] = t[2].inner_html
    project[:region] = t[3].inner_html
    project[:class] = t[4].inner_html
    # Sometimes it holds emails or phone numbers
    if not (t[5]/"span/a").empty?
      project[:holder] = (t[5]/"span/a").inner_html.strip.gsub('"', '\"')
    elsif not (t[5]/"a").empty?
      project[:holder] = (t[5]/"a").inner_html.strip.gsub('"', '\"')
    elsif not (t[5]/"span").empty?
      project[:holder] = (t[5]/"span").inner_html.strip.gsub('"', '\"')
    else
      project[:holder] = t[5].inner_html.strip.gsub('"', '\"')
    end
    project[:amount] = t[6].inner_html
    project[:sent_at] = t[7].inner_html.split('/').reverse.join('-')
    project[:status] = t[8].inner_html
    # TODO: Get the KML file (for geographic information)
    output << "- project:\n"
    project.each do |k,v|
      output << "    #{k}: \"#{v}\"\n"
    end
  end
end
