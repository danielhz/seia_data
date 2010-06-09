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
# - Ruby hpricot gem.
# - iconv unix application to change the encoding in HTML files.
#
# This file create a YAML file for each downloaded HTML page of seia
# proyects list.
#
# USAGE:
# ruby lib/list_to_yaml.rb [options]
#
# For help use:
# ruby lib/list_to_yaml.rb --help

require 'rubygems'  # to include gems (ruby packages)
require 'hpricot'   # to parse bad HTML files
require 'optparse'  # to parse options

# This hash will store options parsed from ARGV.
options = {}

# In next lines we define how options must be parsed. Options are the
# directory where downloaded files are and the prefix of this files.
# Thus we suppose that paths for downloaded files follows the pattern:
#
# #{directory}/#{prefix}#{something}.html
#
# The corresponding YAML file for a HTML file only changes the file
# extension from .html to .yaml
optparse = OptionParser.new do |opts|
  # Usage banner displayed on top of the help screen.
  opts.banner = "Usage: lib/list_to_yaml.rb [options]"
  # Directory of downloaded files
  options[:directory] = 'data'
  opts.on('-d', '--directory DIRECTORY', 'Directory of downloaded pages') do |dir|
    options[:directory] = dir
  end
  # Prefix of downloaded files
  options[:prefix] = 'list-page-'
  opts.on('-p', '--prefix PREFIX', 'File prefix of downloaded pages') do |prefix|
    options[:prefix] = prefix
  end
  # Help screen
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!  # Parse the options

# Remove quotes and white spaces.
clean = Proc.new do |s|
  s.gsub!(/ \"(\w)/, "“")
  s.gsub!(/^\"(\w)/, "“")
  s.gsub!(/(\w)\" /, "”")
  s.gsub!(/(\w)\"$/, "”")
  s.strip!
  s
end

# Parse each document. Some parsed properties have names in sṕanish,
# see the output header below for documentation.
Dir["#{options[:directory]}/#{options[:prefix]}*.html"].sort.each do |file|
  puts "parsing #{file}"  # Verbose way
  # Change the encoding in imput files
  f = file.gsub(/.html$/, '')
  system "iconv #{f}.html -f WINDOWS-1252 -t UTF-8 -o #{f}.conv"
  doc = open("#{f}.conv") { |x| Hpricot(x) }
  system "rm #{f}.conv"
  # The output file
  output = File.new(file.sub(/.html$/, '.yaml'), 'w')
  # The header
  output << <<-EOS
# This file is about a list of projects, each project has the next properties:
# - id:                  number that identify a proyect in the source database.
# - uri:                 uri of the project record.
# - título:              project title.
# - tipoDePresentación:  process in wich the project entered (EIA or DIA)
# - región:              geographical subdivision in wich the proyect is located.
# - tipoDeProyecto:      project type (there is a lot of types like reservoir, piplines,...)
# - titular:             organization or person that is the project owner.
# - inversión:           amount of money to invert in the project.
# - fechaPresentación:   date on wich the project was entered.
# - status:              the current status of the project (aproved, desisted, rejectef,...)

---\n
EOS
  # Parse items in the list
  (doc/"//table[@class='tabla_datos']/tbody/tr").each do |tr|
    t = (tr/"td").map
    project = {}

    # uri
    if (t[1]/"a").empty?
      puts t[1].inspect
      raise
    else
      project[:uri] = (t[1]/"a").first.attributes['href']
    end
    # id
    project[:id] = project[:uri].clone()
    project[:id].sub!('https://www.e-seia.cl/expediente/expediente.php?id_expediente=', '')
    project[:id].sub!('&modo=ficha', '')
    # título
    project[:"título"] = clean.call((t[1]/"a").inner_html)
    # tipoDePresentación
    project[:"tipoDePresentación"] = t[2].inner_html
    # región
    project[:"región"] = t[3].inner_html
    # tipoDeProyecto
    project[:tipoDeProyecto] = t[4].inner_html
    # titular (sometimes it holds emails or phone numbers)
    if not (t[5]/"span/a").empty?
      project[:titular] = clean.call((t[5]/"span/a").inner_html)
    elsif not (t[5]/"a").empty?
      project[:titular] = clean.call((t[5]/"a").inner_html)
    elsif not (t[5]/"span").empty?
      project[:titular] = clean.call((t[5]/"span").inner_html)
    else
      project[:titular] = clean.call(t[5].inner_html)
    end
    # inversión
    project[:"inversión"] = t[6].inner_html
    # fechaDePresentación
    project[:"fechaDePresentación"] = t[7].inner_html.split('/').reverse.join('-')
    # status
    project[:status] = t[8].inner_html

    # Write the project data in the YAML file
    output << "- \"Proyecto\":\n"
    project.each do |k,v|
      output << "    \"#{k}\": \"#{v}\"\n"
    end
  end
  output.close
end
