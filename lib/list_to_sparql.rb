#!/usr/bin/ruby
# -*- coding: utf-8 -*-

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
require 'yaml'
require 'optparse'

# This hash will store options parsed from ARGV.
options = {}

optparse = OptionParser.new do |opts|
  # Usage banner displayed on top of the help screen.
  opts.banner = "Usage: lib/list_to_sparql.rb [options]"
  # Directory
  options[:directory] = 'data'
  opts.on('-d', '--directory DIRECTORY', 'Directory of yaml files') do |dir|
    options[:directory] = dir
  end
  # File prefix
  options[:prefix] = 'list-page-'
  opts.on('-p', '--prefix PREFIX', 'File prefix for yaml files') do |prefix|
    options[:prefix] = prefix
  end
  # Endpoint graph name
  options[:graph] = 'http://chile-datos.cl/data/0.1/seia'
  opts.on('-g', '--graph GRAPH', 'Endpoint graph name') do |graph|
    options[:graph] = graph
  end
  # Help screen
  opts.on( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

Dir["#{options[:directory]}/#{options[:prefix]}*.yaml"].sort.each do |file|
  puts "parsing #{file}"
  obj = YAML::load(open(file))
  out = open(file.sub(/.yaml$/, '.sparql'), 'w')

  sparql_prefix = Proc.new do |prefix, uri|
    out << "PREFIX #{prefix}: <#{uri}>\n"
  end

  sparql_prefix.call 'seia',               'http://chile-datos.cl/data/seia/1/'
  sparql_prefix.call 'proceso',            'http://chile-datos.cl/data/seia/1/Proceso/'
  sparql_prefix.call 'estatus',            'http://chile-datos.cl/data/seia/1/Estatus/'
  sparql_prefix.call 'agente',             'http://chile-datos.cl/data/seia/1/Agente/'
  sparql_prefix.call 'región',             'http://chile-datos.cl/data/seia/1/Región/'
  sparql_prefix.call 'titular',            'http://chile-datos.cl/data/seia/1/Titular/'
  sparql_prefix.call 'tipoDePresentación', 'http://chile-datos.cl/data/seia/1/TipoDePresentación/'
  sparql_prefix.call 'tipoDeProyecto',     'http://chile-datos.cl/data/seia/1/TipoDeProyecto/'

  out << "\nINSERT INTO  <#{options[:graph]}>\n{\n"

  triple = Proc.new do |s,p,o|
    out << "  #{s} #{p} #{o} .\n"
  end

  obj.map { |x| x['Proyecto'] }.each do |proj|
    # Proceso
    process_curi = "proceso:#{proj['id']}"
    # título
    unless proj['title'].nil?
      triple.call process_curi, "seia:título", "\"#{proj['title']}\""
    end
    # ficha
    unless proj['uri'].nil?
      triple.call process_curi, "seia:ficha", "<#{proj['uri']}>"
    end
    # inversión
    unless proj['inversión'].nil?
      triple.call process_curi, "seia:inversión", "\"#{proj['inversión']}\""
    end
    # estatus
    case proj['status'].downcase
    when 'en calificación'
      triple.call process_curi, "seia:estatus", "estatus:EnCalificación"
    when 'aprobado'
      triple.call process_curi, "seia:estatus", "estatus:Aprobado"
    when 'rechazado'
      triple.call process_curi, "seia:estatus", "estatus:Rechazado"
    when 'no admitido a tramitacion'
      triple.call process_curi, "seia:estatus", "estatus:NoAdmitidoATramitación"
    when 'desistido'
      triple.call process_curi, "seia:estatus", "estatus:Desistido"
    when 'no calificado'
      triple.call process_curi, "seia:estatus", "estatus:NoCalificado"
    when 'revocado'
      triple.call process_curi, "seia:estatus", "estatus:Revocado"
    else
      raise "status: #{proj['status']}"
    end
    # tipoProyecto
    if proj['tipoDeProyecto']
      triple.call process_curi, "seia:tipoDeProyecto", "tipoDeProyecto:#{proj['tipoDeProyecto']}"
    end
    # Fecha de presentación
    unless proj['fechaDePresentación'].nil?
      triple.call process_curi, "seia:fechaPresentación", "\"#{proj['fechaDePresentación']}\""
    end
    # titular
    unless proj['titular'].nil?
      triple.call process_curi, "seia:titular", "titular:#{proj['id']}"
      triple.call "titular:#{proj['id']}", "seia:nombre", "\"#{proj['titular']}\""
    end
    # tipoPresentación
    if ["DIA", "EIA"].include? proj["tipoDePresentación"]
      triple.call process_curi, "seia:tipoDePresentación", "tipoDePresentación:#{proj['tipoDePresentación']}"
    end
    # región
    case proj["región"]
    when 'Interregional'
      triple.call process_curi, "seia:región", "región:Interregional"
    when 'Primera'
      triple.call process_curi, "seia:región", "región:I"
    when 'Segunda'
      triple.call process_curi, "seia:región", "región:II"
    when 'Tercera'
      triple.call process_curi, "seia:región", "región:III"
    when 'Cuarta'
      triple.call process_curi, "seia:región", "región:IV"
    when /(^Quinta|V)$/
      triple.call process_curi, "seia:región", "región:V"
    when 'Sexta'
      triple.call process_curi, "seia:región", "región:VI"
    when 'Séptima'
      triple.call process_curi, "seia:región", "región:VII"
    when 'Octava'
      triple.call process_curi, "seia:región", "región:VIII"
    when 'Novena'
      triple.call process_curi, "seia:región", "región:IX"
    when 'Décima'
      triple.call process_curi, "seia:región", "región:X"
    when 'Undécima'
      triple.call process_curi, "seia:región", "región:XI"
    when 'Duodécima'
      triple.call process_curi, "seia:región", "región:XII"
    when 'RM'
      triple.call process_curi, "seia:región", "región:RM"
    when 'Decimocuarta'
      triple.call process_curi, "seia:región", "región:XIV"
    when 'Decimoquinta'
      triple.call process_curi, "seia:región", "región:XV"
    else
      raise "región: #{proj['región']}"
    end
  end
  out << "}\n"
end
