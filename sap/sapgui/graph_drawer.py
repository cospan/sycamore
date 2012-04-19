#!/usr/bin/python

import gtk, gobject, cairo
from gtk import gdk
import math
from types import *
from graph_drawing_area import GraphDrawingArea
from graph_utils import box
import sap_graph_manager as gm
from sap_graph_manager import Node_Type
from sap_graph_manager import Slave_Type


def enum(*sequential, **named):
	enums = dict(zip(sequential, range(len(sequential))), **named)
	return type('Enum', (), enums)

#different ways to draw a box
BOX_STYLE = enum(	'OUTLINE', 
					'SOLID')


"""
Custom Cairo Drawing surface
"""

class GraphDrawer ( GraphDrawingArea ):   
	def __init__(self, sgm):
		GraphDrawingArea.__init__(self)
		self.val = 0
		self.debug = False
		#save the reference to the sgm
		self.sgm = sgm

		self.dash_size = 30
		self.dash_total_size = 4.0
		self.dash_width = 1.0

		#ratio from width of column to box
		self.box_width_ratio = .75
		#ratio from width to height
		self.box_height_ratio = .5

		#the height of the slaves can change when more are added
		self.pslave_height_ratio = .5
		self.mslave_height_ratio = .5

		#padding
		self.x_padding = 10
		self.y_padding = 10

		#boxes
		self.boxes = {}
		self.boxes["host_interface"] = box()
		self.boxes["master"] = box()
		self.boxes["pic"] = box()
		self.boxes["mic"] = box()
		self.boxes["pslaves"] = []
		self.boxes["mslaves"] = []

		#initial prev_width, prev_height
		self.prev_width = -1
		self.prev_height = -1

		ps_count = self.sgm.get_number_of_slaves(Slave_Type.peripheral)
		ms_count = self.sgm.get_number_of_slaves(Slave_Type.memory)

		for i in range (0, ps_count):
			self.boxes["pslaves"].append(box())

		for i in range (0, ms_count):
			self.boxes["mslaves"].append(box())


		self.prev_ps_count = ps_count
		self.prev_ms_count = ms_count
		


	def calculate_box_sizes(self, width, height):
		column_width = self.get_column_width(width)

		#host interface
		b = self.boxes["host_interface"]
		b.width = column_width * self.box_width_ratio
		b.height = b.width * self.box_height_ratio
		b.x = (column_width - b.width) / 2.0
		b.y = (height / 2.0) - b.height / 2.0

		#master
		b = self.boxes["master"]
		b.width = column_width * self.box_width_ratio
		b.height = height - (column_width - b.width)
		b.x = (column_width - b.width) / 2.0 + column_width
		b.y = (column_width - b.width) / 2.0

		#periph interconnect
		b = self.boxes["pic"]
		b.width = column_width * self.box_width_ratio
		b.height = (height / 2.0) - (column_width - b.width) 
		b.x = (column_width - b.width) / 2.0 + 2 * column_width 
		b.y = ((column_width - b.width) / 2.0) 

		#memory interconnect
		b = self.boxes["mic"]
		b.width = column_width * self.box_width_ratio 
		b.height = (height / 2.0) - (column_width - b.width) 
		b.x = (column_width - b.width) / 2.0 + (2 * column_width) 
		b.y = (column_width - b.width) / 2.0 + height / 2.0 


		#peripheral slaves
		for i in range (0, len(self.boxes["pslaves"])):
			b = self.boxes["pslaves"][i]
			b.width = column_width * self.box_width_ratio 
			b.height = b.width * self.pslave_height_ratio  
			b.x = (column_width - b.width) / 2.0 + (column_width * 3) 
			b.y = (column_width - b.width) / 2.0 + \
					i * ((column_width - b.width) + b.height)

		#memory slaves
		for i in range (0, len(self.boxes["mslaves"])):
			b = self.boxes["mslaves"][i]
			b.width = column_width * self.box_width_ratio 
			b.height = b.width * self.mslave_height_ratio  
			b.x = (column_width - b.width) / 2.0 + (column_width * 3) 
			b.y = (column_width - b.width) / 2.0 + \
					i * ((column_width - b.width) + b.height) + \
					height / 2
					

	def set_debug_mode(self, debug):
		self.debug = debug

	def draw(self, width, height):
		
		#compare the current width and height with the previous
		#if there is a different calculate the size of all the boxes
		ps_count = self.sgm.get_number_of_slaves(Slave_Type.peripheral)
		ms_count = self.sgm.get_number_of_slaves(Slave_Type.memory)

		if 	width != self.prev_width or \
			height != self.prev_height or \
			self.prev_ps_count != ps_count or \
			self.prev_ms_count != ms_count :

			print "calculate"
			self.calculate_box_sizes(width, height)

		#save the previous values
		self.prev_width = width
		self.prev_height = height

		self.prev_ps_count = ps_count
		self.prev_ms_count = ms_count

	
		cr = self.cr
		column_width = self.get_column_width(width)

		#if debug flag enabled write the debug in the top left
		if self.debug:
			self.display_debug(width, height)

		#self.draw_wb_lines(width, height)
		
		self.draw_host_interface()
		self.draw_master()
		self.draw_mem_interconnect()
		self.draw_periph_interconnect()
		self.draw_periph_slaves()
		self.draw_mem_slaves()
		self.draw_connections(width, height)


	def draw_host_interface(self):	
		cr = self.cr
		b = self.boxes["host_interface"]

		self.draw_box(	b.x, b.y,
						b.width, b.height,
						text = "host interface",
						r = 1.0, g = 0.0, b = 0.0,
						style = BOX_STYLE.OUTLINE)

	def draw_master(self):
		cr = self.cr
		b = self.boxes["master"]
		self.draw_box(	b.x, b.y,
						b.width, b.height,
						text = "master",
						r = 1.0, g = 1.0, b = 0.0,
						style = BOX_STYLE.OUTLINE)


	def draw_mem_interconnect(self):
		cr = self.cr
		b = self.boxes["mic"]
		self.draw_box(	b.x, b.y,
						b.width, b.height,
						text = "memory ic",
						r = 0.0, g = 1.0, b = 0.0,
						style = BOX_STYLE.OUTLINE)




	def draw_periph_interconnect(self):
		cr = self.cr
		b = self.boxes["pic"]
		self.draw_box(	b.x, b.y,
						b.width, b.height,
						text = "periph ic",
						r = 1.0, g = .5, b = 0.0,
						style = BOX_STYLE.OUTLINE)


	def draw_periph_slaves(self):
		for i in range (0, len(self.boxes["pslaves"])):
			name = self.sgm.get_slave_name_at(i, Slave_Type.peripheral)
			p = self.sgm.get_node(name)
			b = self.boxes["pslaves"][i]
			self.draw_box(	b.x, b.y,
							b.width, b.height,
							text = p.name,
							r = .75, g = .5, b = 0.0,
							style = BOX_STYLE.OUTLINE)


	def draw_mem_slaves(self):
		for i in range (0, len(self.boxes["mslaves"])):
			name = self.sgm.get_slave_name_at(i, Slave_Type.memory)
			p = self.sgm.get_node(name)
			b = self.boxes["mslaves"][i]
			self.draw_box(	b.x, b.y,
							b.width, b.height,
							text = p.name,
							r = .75, g = .5, b = 0.0,
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

		cr.move_to(5, 40)
		cr.show_text("peripheral slaves: " + str(self.prev_ps_count))
		cr.move_to(5, 50)
		cr.show_text("memory slaves: " + str(self.prev_ms_count))




	def get_column_width(self, screen_width=0.0):
		#sanity check
		if screen_width <= 1:
			return screen_width

		return screen_width / 4.0


	def draw_connections(self, width, height):
		cr = self.cr
		column_width = self.get_column_width(width)

		cr.set_line_width(2)
		cr.set_line_cap(cairo.LINE_CAP_SQUARE)
		cr.set_dash([], 0) 

		hi_b = self.boxes["host_interface"]
		m_b = self.boxes["master"]
		pic_b = self.boxes["pic"]
		mic_b = self.boxes["mic"]

		#generate host to master connection
		cr.move_to (hi_b.x + hi_b.width, hi_b.y + hi_b.height / 2.0)
		cr.line_to (m_b.x, m_b.y + m_b.height/2.0)

		#master to peripheral interconnect
		cr.move_to (m_b.x + m_b.width, pic_b.y + pic_b.height / 2.0)
		cr.line_to (pic_b.x, pic_b.y + pic_b.height / 2.0)

		#master to memory interconnect
		cr.move_to (m_b.x + m_b.width, mic_b.y + mic_b.height / 2.0)
		cr.line_to (mic_b.x, mic_b.y + mic_b.height / 2.0)

		#peripheral interconnect to peripheral slaves
		for i in range (0, len(self.boxes["pslaves"])):
			b = self.boxes["pslaves"][i]
			cr.move_to (pic_b.x + pic_b.width, \
						(column_width - b.width) / 2.0 + \
						i * ((column_width - b.width) + b.height) + \
						b.height / 2.0)

			cr.line_to (b.x, b.y + b.height / 2.0)

		#memory interconnect to memory slaves
		for i in range (0, len(self.boxes["mslaves"])):
			b = self.boxes["mslaves"][i]
			cr.move_to (mic_b.x + mic_b.width, \
						(column_width - b.width) / 2.0 + \
						i * ((column_width - b.width) + b.height) + \
						b.height / 2.0 +\
						height / 2.0)

			cr.line_to (b.x, b.y + b.height / 2.0)



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

