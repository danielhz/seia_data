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
Dir["#{options[:directory]}/card-*.html"].sort.each do |file|
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
#
# - id:                  number that identify a proyect in the source database.
# - título:              project title.
# - tipoDePresentación:  process in wich the project entered (EIA or DIA)
# - tipoDeProyecto:      project type (there is a lot of types like reservoir, piplines,...)
# - titular:             organization or person that is the project owner.
# - encargado:           the person in charge of the project evaluation (a CONAMA employe)
# - inversión:           amount of money to invert in the project.
# - status:              the current status of the project (aproved, desisted, rejectef,...)
# - descripción:         project description.
# - representanteLegal:  representative of the project owner (a person).
# - enventos:            a list of events (instances of Evento).
#
# Also some properties have subproperties:
#
# titular:
# - nombre:             name.
# - domicilio:          address (street an number).
# - ciudad:             addrress (city).
# - telefono:           phone number.
# - fax:                fax number.
# - emails:             contact email.
#
# representanteLegal:
# - nombre:             name.
# - domicilio:          address.
# - telefono:           phone number.
# - fax:                fax number.
# - emails:             email.
#
# encargado:
# - nombre:             name.
# - emails:             email.
#
# Evento:
# - name:               status that generates this event.
# - documento:          uri of a related document.
# - número:             un código as 123/2010 where 123 is a serial number and 2010 is a year.
# - fecha:              date.
# - autor:              author of the document (for example: Comisión Nacional del Medio
#                       Ambiente, Magallanes y Antártica Chilena).

Proyecto:
EOS

  # id
  project_id = file.sub(/.*card-/, '').sub(/\.html/, '').to_i
  output << "    \"id\": #{project_id}\n"
  # título
  title = (doc/"//h1").text.sub('Ficha del Proyecto:', '').strip
  output << "    \"título\": \"#{clean.call title}\"\n"
  # tipoDePresentación
  forma = nil
  (doc/"//h2").each do |h|
    text = h.inner_html
    pattern = /Forma de Presentaci&oacute;n:/
    if pattern =~ text
      type = text.sub(pattern, '').strip
      output << "    \"tipoDePresentación\": \"#{type}\"\n"
      forma = h.next_node.next_node
    end
  end
  # tipoDeProyecto
  (forma/"//tr//td").each do |td|
    if /Tipo de Proyecto/ =~ td.inner_html
      tipo = clean.call(td.next_node.next_node.inner_html)
      output << "    \"tipoDeProyecto\": \"#{tipo}\"\n"
    end
  end
  # inversion
  (forma/"//tr//td").each do |td|
    if /Monto de Inversi/ =~ td.inner_html
      inversion = clean.call(td.next_node.next_node.inner_html)
      output << "    \"inversión\": \"#{inversion}\"\n"
    end
  end
  # encargado
  (forma/"//tr//td").each do |td|
    if /Encargado/ =~ td.inner_html
      encargado = td.next_node.next_node
      output << "    \"encargado\":\n"
      # encargado -> teléfono
      (encargado/"//span").each do |span|
        if /Tel.*fono:/ =~ span.attributes['title']
          telefono = span.attributes['title'].sub(/Tel.*fono:/, '').strip
          output << "        \"teléfono\": \"#{telefono}\"\n"
        end
      end
      # encargado -> email y encargado -> nombre
      (encargado/"//a").each do |span|
        if /mailto:/ =~ span.attributes['href']
          email = span.attributes['href'].sub(/mailto:/, '').strip
          nombre = span.inner_html.strip
          output << "        \"email\": \"#{email}\"\n"
          output << "        \"nombre\": \"#{nombre}\"\n"
        end
      end
    end
  end
  # status
  (forma/"//tr//td").each do |td|
    if /Estado/ =~ td.inner_html
      status = clean.call((td.next_node.next_node/"//b").inner_html)
      output << "    \"status\": \"#{status}\"\n"
      # eventos
      tabla = (td.next_node.next_node/"//table[@class='tabla_datos']")
      unless tabla.nil?
        output << "    eventos:\n"
        (tabla/"//tr").each do |tr|
          unless (tr/"//td")[0].nil? or /Estado/ =~ (tr/"//td")[0].inner_html
            output << "        - Evento:\n"
            els = (tr/"//td")
            # status
            output << "            \"status\": \"#{els[0].inner_html}\"\n"
            # documento
            output << "            \"documento\":\n"
            doc_uri = (els[1]/"//a")[0].attributes['href']
            doc_title = (els[1]/"//a")[0].inner_html
            output << "                \"uri\": \"#{doc_uri}\"\n"
            output << "                \"title\": \"#{doc_title}\"\n"
            # número
            output << "            \"número\": \"#{els[2].inner_html}\"\n"
            # fecha
            output << "            \"fecha\": \"#{els[3].inner_html}\"\n"
            # autor
            output << "            \"autor\": \"#{els[4].inner_html}\"\n"
          end
        end
      end
      break
    end
  end
  # titular
  titular = nil
  (doc/"//h2").each do |h|
    text = h.inner_html
    if /Titular/ =~ text
      titular = h.next_node.next_node
    end
  end
  output << "    \"titular\":\n"
  # titular -> nombre
  (titular/"//tr//td").each do |td|
    if /Nombre/ =~ td.inner_html
      nombre = clean.call(td.next_node.next_node.next_node.inner_html)
      output << "        \"nombre\": \"#{nombre}\"\n"
    end
  end
  # titular -> domicilio
  (titular/"//tr//td").each do |td|
    if /Domicilio/ =~ td.inner_html
      domicilio = clean.call(td.next_node.next_node.next_node.inner_html)
      output << "        \"domicilio\": \"#{domicilio}\"\n"
    end
  end
  # titular -> ciudad
  (titular/"//tr//td").each do |td|
    if /Ciudad/ =~ td.inner_html
      ciudad = clean.call(td.next_node.next_node.next_node.inner_html)
      output << "        \"ciudad\": \"#{ciudad}\"\n"
    end
  end
  # titular -> teléfono
  (titular/"//tr//td").each do |td|
    if /Telefono/ =~ td.inner_html
      telefono = clean.call(td.next_node.next_node.next_node.inner_html)
      output << "        \"teléfono\": \"#{telefono}\"\n"
    end
  end
  # titular -> fax
  (titular/"//tr//td").each do |td|
    if /Fax/ =~ td.inner_html
      fax = clean.call(td.next_node.next_node.next_node.inner_html)
      output << "        \"fax\": \"#{fax}\"\n"
    end
  end
  # titular -> teléfono
  (titular/"//tr//td").each do |td|
    if /E-mail/ =~ td.inner_html
      email = clean.call(td.next_node.next_node.next_node.inner_html)
      output << "        \"emails\": \"#{email}\"\n"
    end
  end
  # reprsentanteLegal
  representanteLegal = nil
  (doc/"//h2").each do |h|
    text = h.inner_html
    if /Representante Legal/ =~ text
      representanteLegal = h.next_node.next_node
    end
  end
  output << "    \"representanteLegal\":\n"
  # representanteLegal -> nombre
  (representanteLegal/"//tr//td").each do |td|
    if /Nombre/ =~ td.inner_html
      nombre = clean.call(td.next_node.next_node.next_node.inner_html)
      output << "        \"nombre\": \"#{nombre}\"\n"
    end
  end
  # representanteLegal -> domicilio
  (representanteLegal/"//tr//td").each do |td|
    if /Domicilio/ =~ td.inner_html
      domicilio = clean.call(td.next_node.next_node.next_node.inner_html)
      output << "        \"domicilio\": \"#{domicilio}\"\n"
    end
  end
  # representanteLegal -> ciudad
  (representanteLegal/"//tr//td").each do |td|
    if /Ciudad/ =~ td.inner_html
      ciudad = clean.call(td.next_node.next_node.next_node.inner_html)
      output << "        \"ciudad\": \"#{ciudad}\"\n"
    end
  end
  # representanteLegal -> teléfono
  (representanteLegal/"//tr//td").each do |td|
    if /Telefono/ =~ td.inner_html
      telefono = clean.call(td.next_node.next_node.next_node.inner_html)
      output << "        \"teléfono\": \"#{telefono}\"\n"
    end
  end
  # representanteLegal -> fax
  (representanteLegal/"//tr//td").each do |td|
    if /Fax/ =~ td.inner_html
      fax = clean.call(td.next_node.next_node.next_node.inner_html)
      output << "        \"fax\": \"#{fax}\"\n"
    end
  end
  # representanteLegal -> teléfono
  (representanteLegal/"//tr//td").each do |td|
    if /E-mail/ =~ td.inner_html
      email = clean.call(td.next_node.next_node.next_node.inner_html)
      output << "        \"emails\": \"#{email}\"\n"
    end
  end
  # descripción (TODO)
#  (forma/"//tr//td//div[@class='descripcion_scroll']").each do |d|
#    descripcion = clean.call(d.inner_html)
#    output << "    \"descripción\": \"#{descripcion}\"\n"
#  end
  output.close
end
