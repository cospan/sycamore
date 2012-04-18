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


def enum(*sequential, **named):
	enums = dict(zip(sequential, range(len(sequential))), **named)
	return type('Enum', (), enums)

#different ways to draw a box
BOX_STYLE = enum(	'OUTLINE', 
					'SOLID')



class GraphDrawer ( GraphDrawingArea ):   
	def __init__(self):
		GraphDrawingArea.__init__(self)
		self.val = 0
		self.debug = False

		self.dash_size = 30
		self.dash_total_size = 4.0
		self.dash_width = 1.0

		#ratio from width of column to box
		self.box_width_ratio = .75
		#ratio from width to height
		self.box_height_ratio = .5
		#padding
		self.x_padding = 10
		self.y_padding = 10

	def set_debug_mode(self, debug):
		self.debug = debug

	def draw(self, width, height):
	
		cr = self.cr
		column_width = self.get_column_width(width)

		#if debug flag enabled write the debug in the top left
		if self.debug:
			self.display_debug(width, height)

		self.draw_wb_lines(width, height)
		
		self.draw_host_interface(width, height)
		self.draw_master(width, height)
		self.draw_mem_interconnect(width, height)
		self.draw_periph_interconnect(width, height)


	def draw_host_interface(self, width, height):	
		cr = self.cr
		column_width = self.get_column_width(width)
		#get the box width and height
		box_width = column_width * self.box_width_ratio
		box_height = box_width * self.box_height_ratio

		#location of the host interface is:
		box_x = (column_width - box_width) / 2.0
		box_y = (height/2.0) - box_height / 2.0

		self.draw_box(	box_x, box_y,
						box_width, box_height,
						text = "host interface",
						r = 1.0, g = 0.0, b = 0.0,
						style = BOX_STYLE.OUTLINE)

	def draw_master(self, width, height):
		cr = self.cr
		column_width = self.get_column_width(width)
		master_width = column_width * self.box_width_ratio
		#equal padding around box
		master_height = height - (column_width - master_width)

		#location of the master is
		master_x = (column_width - master_width) / 2.0 + column_width
		master_y = (column_width - master_width) / 2.0

		self.draw_box(	master_x, master_y,
						master_width, master_height,
						text = "master",
						r = 1.0, g = 1.0, b = 0.0,
						style = BOX_STYLE.OUTLINE)


	def draw_mem_interconnect(self, width, height):
		cr = self.cr
		column_width = self.get_column_width(width)
		#interconnect boxes
		mem_ic_width = column_width * self.box_width_ratio

		#interconnect is only taking up half the screen
		mem_ic_height = (height / 2) - (column_width - mem_ic_width)

		mem_ic_x = (column_width-mem_ic_width) / 2.0 + 2 * column_width
		mem_ic_y = (column_width - mem_ic_width) / 2.0

		self.draw_box(	mem_ic_x, mem_ic_y,
						mem_ic_width, mem_ic_height,
						text = "memory ic",
						r = 0.0, g = 1.0, b = 0.0,
						style = BOX_STYLE.OUTLINE)




	def draw_periph_interconnect(self, width, height):
		cr = self.cr
		column_width = self.get_column_width(width)
		per_ic_width = column_width * self.box_width_ratio
		per_ic_height = (height / 2) - (column_width - per_ic_width)

		per_ic_x = (column_width-per_ic_width) / 2.0 + 2 * column_width
		per_ic_y = ((column_width - per_ic_width) / 2.0) + (height / 2)

		self.draw_box(	per_ic_x, per_ic_y,
						per_ic_width, per_ic_height,
						text = "periph ic",
						r = 1.0, g = .5, b = 0.0,
						style = BOX_STYLE.OUTLINE)




	def draw_box (		self, 
						x, y, 
						width, height, 
						text = "",
						r = 0.0, g = 0.0, b = 0.0, 
						style = BOX_STYLE.OUTLINE):
		cr = self.cr
		cr.set_source_rgb(r, g, b)
		cr.rectangle(x, y, width, height)
		if style == BOX_STYLE.SOLID:
			cr.fill()
			cr.stroke()
		elif style == BOX_STYLE.OUTLINE:
			#how do I draw a box with an outline
			cr.fill()
			cr.set_line_width(2.0)
			cr.rectangle(x, y, width, height)
			cr.set_source_rgb(0.0, 0.0, 0.0)
			cr.stroke()

		if len(text) > 0:

			cr.set_source_rgb(0.0, 0.0, 0.0)
	#		cr.select_font_face("Georgia",
	#					cairo.FONT_SLANT_NORMAL, cairo.FONT_WEIGHT_BOLD)
			cr.set_font_size(10)
			x_bearing, y_bearing, twidth, theight = cr.text_extents(text)[:4]
			text_x = 0.5 - twidth / 2 - x_bearing
			text_y = 0.5 - theight / 2 - y_bearing

			pos_x = x + (width / 2.0) + text_x
			pos_y = y + (height / 2.0) + text_y


#			print "text x: " + str(text_x)
#			print "text y: " + str(text_y)

			cr.move_to(pos_x, pos_y)
			cr.show_text(text)
#			print "text pos (x, y) = %d, %d" % (x + text_x, y + text_y)
		

	def draw_wb_lines(self, width, height):
		#draw the column lines

		cr = self.cr
		column_width = self.get_column_width(width)
		cr.set_line_width(2)
		cr.set_line_cap(cairo.LINE_CAP_SQUARE)
		cr.set_dash([self.dash_size/self.dash_total_size, self.dash_size/self.dash_width], 0) 
		
		for i in range (1, 4):
			cr.move_to(column_width * i, 0)
			cr.line_to(column_width * i, height)

		cr.move_to(column_width * 3, height/2)
		cr.line_to(width, height/2)


		#draw the graph
		cr.stroke()
		cr.set_dash([], 0)
		



	def display_debug(self, width, height):
		cr = self.cr
		column_width = self.get_column_width(width)
		cr.move_to(5, 10)
		cr.set_source_rgb(0, 0, 0)

		cr.show_text("debug")
		cr.move_to(5, 20)
		cr.show_text("width, height: " + str(width) + ", " + str(height))
		cr.move_to(5, 30)
		cr.show_text("column width: " + str(column_width))




	def get_column_width(self, screen_width=0.0):
		#sanity check
		if screen_width <= 1:
			return screen_width

		return screen_width / 4.0



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

