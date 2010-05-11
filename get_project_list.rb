#!/usr/bin/ruby

# This file is part of SEIA Crawler.
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

# SEIA Crawler is a crawler for data in http://www.e-seia.cl chilean
# goverment page.
#
# USAGE:
#
# get_project_list.rb <pages>
#
# Where <pages> is the number of pages to download. Pages are in
# decrecending order by creation times. You can lookup the total of
# pages in any repsponse page.

# This crawler works with two functions. First we POST a query to the
# web server and second we iterate with GET over the response pages.
# We need first post the query to save server cookies.

require 'date'

def output_document(i)
  "project_list/list-#{"%09d" % i}.html"
end

def url_encoding_data(data, sep = '&amp;')
  data.map { |k,v| "#{k}=#{v}" }.join(sep)
end

def wget_wait
  # pidof return 0 if there is a wget process running and 256 if not.
  # Into ruby pidof return true or false if thereis or there is not
  # running process.
  while system("pidof wget")
    sleep 2
  end
end

def post_query(options = {})

  # Defaut date range
  options[:start] = Date.today           if options[:start].nil?
  options[:stop]  = Date.new(1994,04,01) if options[:stop].nil?

  # Options (in the seia vocabulary)
  opts = {
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

  puts "downloading 1"
  system("wget -q --load-cookies cookies.txt " +
         "--keep-session-cookies --save-cookies cookies.txt " +
         "--output-document=#{output_document(1)} "  +
         "https://www.e-seia.cl/busqueda/buscarProyectoAction.php " +
         "--post-data='#{url_encoding_data(opts)}'")
  wget_wait
end

def get_query(i)
  puts "downloading #{i}"
  system("wget -q --load-cookies cookies.txt " +
         "--keep-session-cookies --save-cookies cookies.txt " +
         "--output-document=#{output_document(i)} " +
         "https://www.e-seia.cl/busqueda/buscarProyectoAction.php?" +
         "_paginador_refresh=1&_paginador_fila_actual=#{i}")
  wget_wait
end

def download_page(i)
  case i
  when 1
    post_query
  else
    get_query(i)
  end
end

# Crawl
if ARGV.empty?
  puts "usage:\nget_project_list.rb <pages>"
else
  pages = ARGV[0].to_i
  # make directory if not exists
  # if not os.path.isdir("seia_project_list"): os.mkdir("seia_project_list")
  # download pages
  (1..pages).each { |i| download_page(i) }
end

