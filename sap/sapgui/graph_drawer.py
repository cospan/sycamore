#!/usr/bin/python

import gtk, gobject, cairo
from gtk import gdk
import math
from types import *

"""Custom Drawing Area"""
class GraphDrawingArea(gtk.DrawingArea):
	def __init__(self):
		super (GraphDrawingArea, self).__init__()
		
		self.connect ( "expose_event", self.do_expose_event )
		gobject.timeout_add(50, self.tick)

	def tick (self):
		self.alloc = self.get_allocation()
		rect = gtk.gdk.Rectangle (	self.alloc.x, \
									self.alloc.y, \
									self.alloc.width, \
									self.alloc.height )

#		print "Type: " + str(type(self))
#		if type(self.window) is NoneType:
#			return True
#		else:
		self.window.invalidate_rect ( rect, True )        

		return True # Causes timeout to tick again


	def do_expose_event( self, widget, event ):
#		print "expose event"
		self.cr = self.window.cairo_create( )
		self.draw( *self.window.get_size())


class GraphDrawer ( GraphDrawingArea ):   
	def __init__(self):
		GraphDrawingArea.__init__(self)
		self.val = 0

	def draw(self, width, height):
#		print "v: " + str(self.val)
#		self.val += 1
		cr = self.cr
		cr.set_source_rgb(1, 0, 0)
		cr.rectangle (50, 50, 100, 60)
		cr.fill()
#		cr.fill_preserve()
		cr.stroke()


		cr.set_source_rgb(0, 1, 0)
		cr.rectangle (200, 50, 100, 60)
		cr.fill()
#		cr.fill_preserve()
		cr.stroke()


#		cr.set_line_width(10)
#		cr.set_line_cap(cairo.LINE_CAP_ROUND)
#		cr.stroke()
	def draw_graph(self):
		print "drawing graph"

	def draw_node(self):
		print "draw node"

	def draw_edge(self, node1, node2):
		print "connecting nodes"




def run (Widget):
	print "in run"
	window = gtk.Window()
	window.set_default_size(640, 430)
	window.connect ("delete-event", gtk.main_quit)
	window.set_size_request(400, 400)
	widget = Widget()
	widget.show()
	window.add(widget)
	window.present()
	gtk.main()
	

if __name__ == "__main__":
	print "in main"
	run (GraphDrawer)

