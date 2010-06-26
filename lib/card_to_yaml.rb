#!/usr/bin/ruby
# -*- coding: utf-8 -*-

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
#Dir["#{options[:directory]}/card-*.html"].sort.each do |file|
p Dir["#{options[:directory]}/card-0000*.html"].sort.select{ |x| x > "#{options[:directory]}/card-0000017210.html"}.size
Dir["#{options[:directory]}/card-0000*.html"].sort.select{ |x| x > "#{options[:directory]}/card-0000017210.html"}.each do |file|
#Dir["#{options[:directory]}/card-0000031488.html"].sort.each do |file|
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
# - consultora:
# - consultor:
# - enventos:            a list of events (instances of Evento).
# - fechaPublicaciónDiarioOficial: date of publication in the official newspaper.
# - fechaPublicaciónDiarioDeCirculaciónNacionalORegional: date of publication in a newspaper
#                        with Nacional or Local coverage.
# - participaciónCiudadana: deadline to recive comments from citizens.
# - efectos:             project effects.
#
# Also some properties have subproperties:
#
# titular | consultora | representanteLegal | consultor:
# - nombre:             name.
# - domicilio:          address (street an number).
# - ciudad:             addrress (city).
# - telefono:           phone number.
# - fax:                fax number.
# - emails:             contact email.

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

  # Get text
  get_text = Proc.new do |node|
    node.inner_text.gsub("\302\240", " ").gsub("\r"," ").gsub("\n"," ").split(" ").join(" ").strip
  end

  # Write a leaf
  write_data = Proc.new do |level, name, value|
    output << " "*4*level + "\"#{name}\": \"#{value}\"\n"
  end

  # Parse a leaf
  parse_leaf = Proc.new do |node,level,name|
    value = get_text.call(node)
    write_data.call(level, name, clean.call(value))
  end

  # Parse and write data
  parse_data = Proc.new do |table, key, action|
    (table/"//tr//td").each do |k|
      if key =~ k.inner_html
        # puts "found #{key}"
        node = k.next
        while(!node.nil?)
          text = get_text.call(node)
          action.call(node) if text != '' and text != ':'
          node = node.next
        end
      end
    end
  end

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

  parse_forma_leaf = Proc.new do |key, name|
    parse_data.call(forma, key, Proc.new{ |n| parse_leaf.call(n, 1, name) })
  end

  parse_forma_leaf.call(/^Tipo de Proyecto$/, 'tipoDeProyecto')
  parse_forma_leaf.call(/^Monto de Inversi&oacute;n$/, 'inversión')
  parse_forma_leaf.call(/^Efectos$/, 'efectos')
  parse_forma_leaf.call(/^Fecha Publicaci&oacute;n Diario Oficial$/, 'fechaPublicaciónDiarioOficial')
  parse_forma_leaf.call(/^Fecha Publicación Diario de Circulación Nacional o Regional$/, 'fechaPublicaciónDiarioDeCirculaciónNacionalOReginal')
  parse_forma_leaf.call(/^Participaci&oacute;n Ciudadana$/, 'participaciónCiudadana')

  parse_data.call(forma, /^Encargado$/, Proc.new { |node|
                    output << " "*4 + "\"encargado\":\n"
                    # encargado -> teléfono
                    (node/"//span").each do |span|
                      if /^Telefono:$/ =~ span.attributes['title']
                        telefono = span.attributes['title'].sub(/Telefono:/, '').strip
                        write_data.call(2, 'teléfono',  telefono)
                      end
                    end
                    # encargado -> email y encargado -> nombre
                    (node/"//a").each do |span|
                      if /mailto:/ =~ span.attributes['href']
                        email = span.attributes['href'].sub(/mailto:/, '').strip
                        nombre = span.inner_html.strip
                        write_data.call(2, 'email',  email)
                        write_data.call(2, 'nombre',  nombre)
                      end
                    end
                  })
  # status
  parse_data.call(forma, /^Estado$/, Proc.new { |node|
                    unless (node/'//b').empty?
                      # Case: with events
                      write_data.call(1, 'status', get_text.call(node))
                      tabla = (node/"//table[@class='tabla_datos']")
                      unless tabla.nil?
                        output << "    eventos:\n"
                        (tabla/"//tr").each do |tr|
                          unless (tr/"//td")[0].nil? or /Estado/ =~ (tr/"//td")[0].inner_html
                            output << " "*8 + "- Evento:\n"
                            els = (tr/"//td")
                            write_data.call(2, 'status', get_text.call(els[0]))
                            output << " "*8 + "\"documento\":\n"
                            unless (els[1]/"//a").empty
                              doc_uri   = (els[1]/"//a")[0].attributes['href']
                              doc_title = get_text.call((els[1]/"//a")[0])
                            else
                              doc_title = get_text.call(els[1])
                            end
                            write_data.call(3, 'uri', doc_uri) unless doc_uri.nil?
                            write_data.call(3, 'título', doc_title)
                            write_data.call(2, 'número', els[2].inner_html)
                            write_data.call(2, 'fecha', els[3].inner_html)
                            write_data.call(2, 'autor', els[4].inner_html)
                          end
                        end
                      end
                    else
                      # Case without elements
                      write_data.call(1, 'status', get_text.call(node))
                    end
                  })
  parse_agent = Proc.new do |key, name|
    (doc/"//h2").each do |h|
      text = h.inner_html
      if key =~ text
        node = h.next_sibling
        # if node.nil?
        #   # When h2 is in <tbody><h2>...</h2><tr>...</tr>
        #   node = (h/'..//tbody')[0]
        #   p node
        # end
        output << " "*4 + "\"#{name}\":\n"
        parse_subcomponent = Proc.new do |key, name|
          parse_data.call(node, key, Proc.new{ |n| parse_leaf.call(n, 2, name) })
        end
        parse_subcomponent.call(/^Nombre$/, 'nombre')
        parse_subcomponent.call(/^Domicilio$/, 'domicilio')
        parse_subcomponent.call(/^Ciudad$/, 'ciudad')
        parse_subcomponent.call(/^Telefono$/, 'teléfono')
        parse_subcomponent.call(/^Fax$/, 'fax')
        parse_subcomponent.call(/^E-mail$/, 'email')
      end
    end
  end

  parse_agent.call(/Titular/, 'titular')
  parse_agent.call(/Representante Legal/, 'representanteLegal')
  parse_agent.call(/Consultora/, 'consultora')
  parse_agent.call(/Consultor/, 'consultor')

  # descripción
  (forma/"//tr//td//div[@class='descripcion_scroll']").each do |node|
    text = get_text.call(node)
    unless text == ''
      write_data.call(1, 'descripción', get_text.call(node))
    end
  end
  output.close
end
