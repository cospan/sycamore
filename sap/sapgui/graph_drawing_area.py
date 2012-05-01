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
		if self.alloc.width < 0:
			return True

		if self.alloc.height < 0:
			return True

		rect = gtk.gdk.Rectangle (	0, \
									0, \
									self.alloc.width, \
									self.alloc.height )
		self.window.invalidate_rect ( rect, True )        

		return True # Causes timeout to tick again


	def do_expose_event( self, widget, event ):
#		print "expose event"
		self.cr = self.window.cairo_create( )
		self.draw( *self.window.get_size())



