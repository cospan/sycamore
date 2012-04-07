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
		cr.set_source_rgb(1, 1, 0)
		cr.arc(320,240,100, 0, 2*math.pi)
		cr.fill_preserve()

		cr.set_source_rgb(0, 0, 0)
		cr.stroke()

		cr.arc(280,210,20, 0, 2*math.pi)
		cr.arc(360,210,20, 0, 2*math.pi)
		cr.fill()

		cr.set_line_width(10)
		cr.set_line_cap(cairo.LINE_CAP_ROUND)
		cr.arc(320, 240, 60, math.pi/4, math.pi*3/4)
		cr.stroke()




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

