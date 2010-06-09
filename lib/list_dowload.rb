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
# - Unix wget command
# - Ruby hpricot gem
#
# This script dowlnloads all summary pages from the SEIA site.
# Each page contains a list of summaries for projects in the SEIA
# system. To download all pages use:
#
# ruby lib/list_download.rb [options]
#
# For help use:
#
# ruby lib/list_download.rb --help

require 'date'
require 'rubygems'
require 'hpricot'
require 'optparse'

# This hash will store options parsed from ARGV.
options = {}

optparse = OptionParser.new do |opts|
  # Usage banner displayed on top of the help screen.
  opts.banner = "Usage: lib/list_download.rb [options]"
  # Directory
  options[:directory] = 'data'
  opts.on('-d', '--directory DIRECTORY', 'Directory to store downloaded files') do |dir|
    options[:directory] = dir
  end
  # File prefix
  options[:prefix] = 'list-page-'
  opts.on('-p', '--prefix PREFIX', 'File prefix for downloaded pages') do |prefix|
    options[:prefix] = prefix
  end
  # Start date
  options[:start] = Date.new(1994,04,01)
  opts.on('-b', '--bottom-date DATE', 'Bottom limit of dates') do |date|
    options[:start] = date
  end
  # Stop date
  options[:stop] = Date.today
  opts.on('-t', '--top-date DATE', 'Top limit of dates') do |date|
    options[:stop] = date
  end
  # First page
  options[:pages] = nil
  opts.on('-r', '--range RANGE', 'Range of pages to be stored like 10..20') do |range|
    pages = eval("(#{range})")
    if Range === pages
      options[:pages] = pages
    else
      puts "Bad format for range #{range}"
      raise
    end
  end
  # Help screen
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!
    
# Options in the seia vocabulary
seia_options = {
  :ano_desde          => options[:start].year,
  :ano_hasta          => options[:stop].year,
  :ano_hastac         => options[:stop].year,
  :anoc_desde         => options[:start].year,
  :busca              => true,
  :dia_desde          => options[:start].day,
  :dia_hasta          => options[:stop].day,
  :dia_hastac         => options[:stop].day,
  :diac_desde         => options[:start].day,
  :estado             => '',
  :externo            => 1,
  :id_tipoexpediente  => '',
  :mes_desde          => options[:start].month,
  :mes_hasta          => options[:stop].month,
  :mesc_desde         => options[:start].month,
  :mes_hastac         => options[:stop].month,
  :modo               => 'normal',
  :nombre             => '',
  :presentacion       => 'AMBOS',
  :sector             => ''
}

# The ouput file name
output_document = Proc.new do |i|
  "#{options[:directory]}/#{options[:prefix]}#{"%08d" % i}.html"
end

# Codes a hash as an URL data string.
url_encoding_data = Proc.new do |data|
  data.map { |k,v| "#{k}=#{v}" }.join('&')
end

# Wait the end of all wget processes
wget_wait = Proc.new do
  # pidof return 0 if there is a wget process running and 256 if not.
  # Into ruby pidof return true or false if thereis or there is not
  # running process.
  while system("pidof wget")
    sleep 2
  end
end

# Post a query to the server and store the first page.
post_query = Proc.new do
  system("wget -q --load-cookies cookies.txt " +
         "--keep-session-cookies --save-cookies cookies.txt " +
         "--output-document=#{output_document.call(1)} "  +
         "https://www.e-seia.cl/busqueda/buscarProyectoAction.php " +
         "--post-data='#{url_encoding_data.call(seia_options)}'")
  wget_wait.call
end

# Post query for page i.
get_query = Proc.new do |i|
  system("wget -q --load-cookies cookies.txt " +
         "--keep-session-cookies --save-cookies cookies.txt " +
         "--output-document=#{output_document.call(i)} " +
         "https://www.e-seia.cl/busqueda/buscarProyectoAction.php?" +
         "_paginador_fila_actual=#{i}")
  wget_wait.call
end

# Create the directory to store downloaded pages
unless (File.exist? options[:directory] and
        File.directory? options[:directory])
  Dir.mkdir(options[:directory])
end

# Download and store pages.
print "downloading 1/"
post_query.call(options)
doc = open(output_document.call(1)) { |f| Hpricot(f) }
pages = (doc/"//select[@name='pagina_offset']/option").size
print "#{pages}\n"
range = (2..pages)
unless options[:pages].nil?
  first = [range.first, options[:pages].first].max
  last  = [range.last, options[:pages].last].min
  range = (first..last)
end
range.each do |i|
  puts "downloading #{i}/#{pages}"
  get_query.call(i)
end
