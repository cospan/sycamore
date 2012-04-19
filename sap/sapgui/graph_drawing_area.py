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



