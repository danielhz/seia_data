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

# This file prints a YAML file from data in dowloaded project list files
# USAGE:
# ruby project_list_parser.rb > projects.yaml

require 'rubygems'
require 'hpricot'
require 'open-uri'

print "--- !chile-datos.degu.cl/^seia_project_list\n"
Dir['seia_project_list/list-*.html'].sort.each do |file|
  doc = open(file) { |f| Hpricot(f) }
  # Parse the projects
  (doc/"//table[@class='tabla_datos']/tbody/tr").each do |tr|
    t = (tr/"td").map
    project = {}

    project[:uri] = (t[1]/"a").first.attributes['href']
    project[:id] = project[:uri].sub('https://www.e-seia.cl/expediente/expediente.php?id_expediente=', '').sub('&modo=ficha', '')
    project[:title] = (t[1]/"a").inner_html
    project[:type] = t[2].inner_html
    project[:region] = t[3].inner_html
    project[:class] = t[4].inner_html
    # Sometimes it holds emails or phone numbers
    if not (t[5]/"span/a").empty?
      project[:holder] = (t[5]/"span/a").inner_html
    elsif not (t[5]/"a").empty?
      project[:holder] = (t[5]/"a").inner_html
    elsif not (t[5]/"span").empty?
      project[:holder] = (t[5]/"span").inner_html
    else
      project[:holder] = t[5].inner_html
    end
    project[:amount] = t[6].inner_html
    project[:sent_at] = t[7].inner_html.split('/').reverse.join('-')
    project[:status] = t[8].inner_html
    # TODO: Get the KML file (for geographic information)

    print "- project:\n"
    project.each do |k,v|
      print "    #{k}: \"#{v}\"\n"
    end

    # project_file = File.new("projects/project-%09d.html" % project[:id], 'w')
    # project_file << open(uri).read
    # project_file.close
  end
end
