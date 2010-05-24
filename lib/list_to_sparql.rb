#!/usr/bin/ruby

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
  options[:graph] = 'http://chile-datos.degu.cl/data/0.1/seia'
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

  sparql_prefix.call 'rdf',   'http://www.w3.org/1999/02/22-rdf-syntax-ns#'
  sparql_prefix.call 'owl',   'http://www.w3.org/2002/07/owl#'
  sparql_prefix.call 'dc',    'http://purl.org/dc/elements/1.1/'
  sparql_prefix.call 'cl',    'http://chile-datos.degu.cl/data/0.1/'
  sparql_prefix.call 'geo',   'http://chile-datos.degu.cl/data/0.1/geo'
  sparql_prefix.call 'reg',   'http://chile-datos.degu.cl/data/0.1/geo/Region/'
  sparql_prefix.call 'class', 'http://chile-datos.degu.cl/data/0.1/seia/class/'
  sparql_prefix.call 'pred',  'http://chile-datos.degu.cl/data/0.1/seia/predicate/'
  sparql_prefix.call 'dtype', 'http://chile-datos.degu.cl/data/0.1/seia/datatype/'
  sparql_prefix.call 'proc',  'http://chile-datos.degu.cl/data/0.1/seia/element/Proceso/'
  sparql_prefix.call 'dia',   'http://chile-datos.degu.cl/data/0.1/seia/DIA/'

  out << "\nINSERT INTO  <#{options[:graph]}>\n{\n"

  triple = Proc.new do |s,p,o|
    out << "  #{s} #{p} #{o} .\n"
  end

  obj.map { |x| x['project'] }.each do |proj|
    # Process CURI
    process_curi = "proc:#{proj['id']}"
    # Process type
    case proj["type"]
    when "DIA"
      triple.call process_curi, "rdf:type", "seia:DIA"
    when "EIA"
      triple.call process_curi, "rdf:type", "seia:EIA"
    else
      puts "sin tipo en #{file}\n #{proj.inspect}\n"
      raise
    end
    # Process source
    triple.call process_curi, "dc:source", "<#{proj['uri']}>"
    unless proj['title'].nil?
      triple.call process_curi, "dc:title", "\"#{proj['title']}\""
    end
    # Fecha de presentación
    unless proj['sent_at'].nil?
      triple.call process_curi, "seia:fechaPresentación", proj['sent_at']
    end
    # Tipologías
  end
  out << "}\n"
end
