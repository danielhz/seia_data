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

# Requirements for this script:
#
# - rest_client
#
# This script dowlnloads all summary pages from the SEIA site.
# Each page contains a list of summaries for projects in the SEIA
# system. To download all pages use:
#
# ruby lib/project_card_download.rb [options]
#
# For help use:
#
# ruby lib/project_card_download.rb --help

require 'rubygems'     # to include gems (ruby packages)
require 'optparse'     # to parse options
require 'yaml'         # to parse yaml files
require 'rest_client'  # to download files

# This hash will store options parsed from ARGV.
options = {}

# In next lines we define how options must be parsed. Options are the
# directory where YAML files are and the prefix of this files.
# Thus we suppose that paths for downloaded files follows the pattern:
#
# #{directory}/#{prefix}#{something}.yaml
#
# Each downloaded file will be named folling the pattern:
#
# #{directory}/card-#{"%010d" % id}.html
#
# Where id is the variable id for the project in the YAML file.
optparse = OptionParser.new do |opts|
  # Usage banner displayed on top of the help screen.
  opts.banner = "Usage: lib/project_card_download.rb [options]"
  # Directory of downloaded files
  options[:directory] = 'data'
  opts.on('-d', '--directory DIRECTORY', 'Directory of YAML files') do |dir|
    options[:directory] = dir
  end
  # Prefix of downloaded files
  options[:prefix] = 'list-page-'
  opts.on('-p', '--prefix PREFIX', 'File prefix of YAML files') do |prefix|
    options[:prefix] = prefix
  end
  # Help screen
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!  # Parse the options

# Read each YAML file
Dir["#{options[:directory]}/#{options[:prefix]}*.yaml"].sort.each do |file|
  puts "parsing #{file}"
  obj = YAML::load(open(file))

  # Download each project card
  obj.map { |x| x['Proyecto'] }.each do |proj|
    project_id = "#{proj['id']}"
    print "Projecto #{project_id} "
    params = {
      :id_expediente => project_id,
      :idExpediente  => project_id,
      :modo => 'ficha'
    }
    RestClient.get("https://www.e-seia.cl/expediente/expediente.php", params) do |res|
      if res.nil?
        puts 'empty response'
      else
        puts 'OK'
        out = open("#{options[:directory]}/card-#{"%010d" % project_id}.html", 'w')
        out << res
        out.close
      end
    end
  end
end
