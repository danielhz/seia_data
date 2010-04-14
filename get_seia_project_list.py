#!/usr/bin/python

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
# download_project_list.py <pages>
#
# Where <pages> is the number of pages to download. Pages are in
# decrecending order by creation times. You can lookup the total of
# pages in any repsponse page.


import os
import sys

# This crawler works with two functions. First we POST a query to the
# web server and second we iterate with GET over the response pages.
# We need first post the query to save server cookies.

def postQuery():
	cmd = "wget --load-cookies cookies.txt " + \
	    "--keep-session-cookies --save-cookies cookies.txt " + \
	    "--output-document=html/list-" + ("%09d" % 1) + ".html "  + \
	    "https://www.e-seia.cl/busqueda/buscarProyectoAction.php " + \
	    "--post-data=" + \
	    "'ano_desde=1994&ano_hasta=2010&ano_hastac=2010&" + \
	    "anoc_desde=1994&busca=true&dia_desde=1&dia_hasta=13&" + \
	    "dia_hastac=13&diac_desde=1&estado=&externo=1&" + \
	    "id_tipoexpediente=&mes_desde=4&mes_hasta=4&" + \
	    "mes_hastac=4&mesc_desde=4&modo=normal&nombre=&" + \
	    "presentacion=AMBOS&sector='"
	print(cmd)

def getQuery(i):
	cmd = "wget --load-cookies cookies.txt " + \
	    "--keep-session-cookies --save-cookies cookies.txt " + \
	    "--output-document=html/list-" + ("%09d" % i) + ".html " + \
	    "https://www.e-seia.cl/busqueda/buscarProyectoAction.php?" + \
	    "_paginador_refresh=1&_paginador_fila_actual=" + repr(i)
	os.system(cmd)
	x = os.wait()
	print(x)

# Crawl
if len(sys.argv) != 2:
	print "usage:\nseia_crawl_lists.py <pages>"
else:
	pages = sys.argv[1]
	# make directory if not exists
	if not os.path.isdir("lists"): os.mkdir("lists")
	# download pages
	postQuery()
	for page in range(2, int(pages)+1):
		getQuery(page)

