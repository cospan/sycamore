#!/usr/bin/python

import pygtk
pygtk.require('2.0')
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

def motion_notify_event (widget, event):
	x = 0
	y = 0
	state = event.state

	if event.is_hint:
		x, y, state = event.window.get_pointer()
	else:
		x = event.x
		y = event.y
		state = event.state

	widget.set_pointer_value(x, y)

	if state & gtk.gdk.BUTTON1_MASK:
		widget.start_moving()
#		widget.set_moving_state(1)


	return True

def button_press_event (widget, event):
	x, y, state = event.window.get_pointer()
	widget.button_press()
	widget.set_pointer_value(x, y)
	return True

def button_release_event (widget, event):
	x, y, state = event.window.get_pointer()
	widget.set_pointer_value(x, y)
	widget.stop_moving()
	widget.button_release()
	return True

"""
Custom Cairo Drawing surface
"""

class GraphDrawer ( GraphDrawingArea ):   
	def __init__(self, sgm):
		GraphDrawingArea.__init__(self)
		self.val = 0
		self.debug = False
		self.dy = 10
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
		self.boxes["trash"] = box()

		self.temp_box = box()

		#initial prev_width, prev_height
		self.prev_width = -1
		self.prev_height = -1
		self.recalculate = False

		ps_count = self.sgm.get_number_of_slaves(Slave_Type.peripheral)
		ms_count = self.sgm.get_number_of_slaves(Slave_Type.memory)

		for i in range (0, ps_count):
			self.boxes["pslaves"].append(box())

		for i in range (0, ms_count):
			self.boxes["mslaves"].append(box())


		self.prev_ps_count = ps_count
		self.prev_ms_count = ms_count

		#add event handling for the mouse
		self.p_x = 0
		self.p_y = 0
		self.moving = 0

		self.connect("motion_notify_event", motion_notify_event)
		self.connect("button_press_event", button_press_event)
		self.connect("button_release_event", button_release_event)

		self.set_events(	gtk.gdk.EXPOSURE_MASK
							| gtk.gdk.LEAVE_NOTIFY_MASK
							| gtk.gdk.BUTTON_PRESS_MASK
							| gtk.gdk.BUTTON_RELEASE_MASK
							| gtk.gdk.POINTER_MOTION_MASK
							| gtk.gdk.POINTER_MOTION_HINT_MASK)

		self.selected_node = None
		self.rel_x = 0
		self.rel_y = 0

		self.mov_x = 0
		self.mov_y = 0
		self.slave_add_callback = None
		self.slave_remove_callback = None
		self.slave_move_callback = None
		self.new_slave = 0

	def add_new_slave(self, new_node):
		"""
		adds a new slave visually, when the slave is actually
		dropped then the sap_controller will actually add the
		real device, so this is more a means to visually add
		a slave
		"""

		#set the new slave as the selected slave 

		#fake a move input, this will tell the graph drawer to
		#draw the slave moving

		#setup the relative position and a fake pointer location
		#off the screen

	def set_slave_add_callback(self, slave_add_callback):
		self.slave_add_callback = slave_add_callback

	def set_slave_remove_callback(self, slave_remove_callback):
		self.slave_remove_callback = slave_remove_callback

	def set_slave_move_callback(self, slave_move_callback):
		self.slave_move_callback = slave_move_callback

	def can_node_move(self, node):
		#can only moved 
		if node is None:
			return False

		if node.node_type != Node_Type.slave:
			return False

		#can't move the DRT
		if node.slave_type == Slave_Type.peripheral and node.slave_index == 0:
			return False

		return True
		
	def start_moving(self):
		if self.moving == 1:
			return
		# the node should have been selected in set_button_state
		node = self.selected_node
		if self.can_node_move(node):
			#store the pointer's relative position to the top of the box
			b = None
			if node.slave_type == Slave_Type.peripheral:
				b = self.boxes["pslaves"][node.slave_index]
			else:
				b = self.boxes["mslaves"][node.slave_index]

			self.rel_x = self.p_x - b.x 
			self.rel_y = self.p_y - b.y
			
			#tell everyone we are moving
			self.moving = 1

	def in_slave_column(self):
		cw = self.get_column_width(self.prev_width)
		sc_left = cw * 3
		sc_right = cw * 4
		sc_top = 0
		sc_bot = self.prev_height

		if self.mov_x < sc_left:
			return False
		if self.mov_x > sc_right:
			return False
		if self.mov_y < sc_top:
			return False
		if self.mov_y > sc_bot:
			return False

		return True

	def in_trash_can(self):
		cw = self.get_column_width(self.prev_width)
		b = self.boxes["trash"]

		if self.p_x < b.x:
			return False
		if self.p_x > b.x + b.width:
			return False
		if self.p_y < b.y:
			return False
		if self.p_y > b.y + b.height:
			return False
		return True



		

	def stop_moving (self):
		if self.moving == 0:
			return

		if self.debug:
			print "dropping slave"

		self.moving = 0
		node = self.selected_node

		#check to see if the slave is within the slave column

		b = None
		if node.slave_type == Slave_Type.peripheral:
			b = self.boxes["pslaves"][node.slave_index]
		else:
			b = self.boxes["mslaves"][node.slave_index]

		#check if were are within the slave area
		if self.debug:
			print "check to see if we're in slave area"

		if self.in_trash_can():
			if self.debug:
				print "removing slave"
			if self.new_slave:
				print "can't remove a new slave"
				return
			if (self.slave_remove_callback is not None):
				self.slave_remove_callback(node.slave_type, node.slave_index)

		if not self.in_slave_column():
			return

		if self.debug:
			print "in slave area"

		mid_x = self.mov_x + (b.width / 2.0)
		mid_y = self.mov_y + (b.height / 2.0)


		drop_type = None
		sl = []
		if mid_y < (self.prev_height / 2.0):
			if self.debug:
				print "in peripheral bus"
			drop_type = Slave_Type.peripheral
			sl = self.boxes["pslaves"]

		else:
			if self.debug:
				print "in memory bus"
			drop_type = Slave_Type.memory
			sl = self.boxes["mslaves"]

		#now find where in the bus it is dropped
		drop_index = 0
		for slave_box in sl:
			if mid_y < slave_box.y + (slave_box.height / 2.0):
				break
			else:
				drop_index += 1

		if self.debug:
			print "drop location is at %d" % drop_index

		if self.new_slave == 1:
			if self.debug:
				print "adding new slave"
			if (self.slave_add_callback is not None):
				self.slave_add_callback(node, drop_type, drop_index)

		else:
			if self.debug:
				print "moving existing slave"

			b = None
			result = False
			if (self.slave_move_callback is not None):
				result = self.slave_move_callback(	node.slave_type,
													node.slave_index,
													drop_type,
													drop_index)

#			if result:

#				if node.slave_type == Slave_Type.peripheral:
#					b = self.boxes["pslaves"][node.slave_index]
#					self.boxes["pslaves"].remove(b)
#				else:
#					b = self.boxes["mslaves"][node.slave_index]
#					print "index: " + str(node.slave_index)
#					self.boxes["mslaves"].remove(b)
#
#				if drop_type == Slave_Type.peripheral:
#					self.boxes["pslaves"].insert(drop_index, b)
#				else:
#					self.boxes["mslaves"].insert(drop_index, b)

		
	
	def button_press(self):
		node_name = self.get_selected_name(self.p_x, self.p_y)
		if len(node_name) > 0:
			self.selected_node = self.sgm.get_node(node_name)


	def button_release(self):
		self.selected_node = None

	def set_pointer_value(self, x, y):
		self.p_x = x
		self.p_y = y

	def force_update(self):
		ps_count = self.sgm.get_number_of_slaves(Slave_Type.peripheral)
		ms_count = self.sgm.get_number_of_slaves(Slave_Type.memory)

		self.boxes["pslaves"] = []
		self.boxes["mslaves"] = []

		for i in range (0, ps_count):
			self.boxes["pslaves"].append(box())

		for i in range (0, ms_count):
			self.boxes["mslaves"].append(box())

		self.recalculate = True


	def calculate_box_sizes(self, width, height):
		column_width = self.get_column_width(width)


		#trash can
		b = self.boxes["trash"]
		b.width = column_width * self.box_width_ratio
		b.height = b.width * self.box_height_ratio
		b.x = column_width + (column_width - b.width) / 2.0
		b.y = height - b.height - ((column_width - b.width) / 2.0)
		b.r = 1.0
		b.g = 1.0
		b.b = 1.0

		#host interface
		b = self.boxes["host_interface"]
		b.width = column_width * self.box_width_ratio
		b.height = b.width * self.box_height_ratio
		b.x = (column_width - b.width) / 2.0
		b.y = (height / 2.0) - b.height / 2.0
		b.r = 1.0
		b.g = 0.0
		b.b = 0.0

		#master
		b = self.boxes["master"]
		b.width = column_width * self.box_width_ratio
		b.height = height - (column_width - b.width)
		b.x = (column_width - b.width) / 2.0 + column_width
		b.y = (column_width - b.width) / 2.0
		b.r = 1.0
		b.g = 0.5
		b.b = 0.0

		#periph interconnect
		b = self.boxes["pic"]
		b.width = column_width * self.box_width_ratio
		b.height = (height / 2.0) - (column_width - b.width) 
		b.x = (column_width - b.width) / 2.0 + 2 * column_width 
		b.y = ((column_width - b.width) / 2.0) 
		b.r = 1.0
		b.g = 1.0
		b.b = 0.0

		#memory interconnect
		b = self.boxes["mic"]
		b.width = column_width * self.box_width_ratio 
		b.height = (height / 2.0) - (column_width - b.width) 
		b.x = (column_width - b.width) / 2.0 + (2 * column_width) 
		b.y = (column_width - b.width) / 2.0 + height / 2.0 
		b.r = 1.0
		b.g = 1.0
		b.b = 0.0



		#peripheral slaves
		for i in range (0, len(self.boxes["pslaves"])):
			b = self.boxes["pslaves"][i]
			b.width = column_width * self.box_width_ratio 
			b.height = b.width * self.pslave_height_ratio  
			b.x = (column_width - b.width) / 2.0 + (column_width * 3) 
			b.y = (column_width - b.width) / 2.0 + \
					i * ((column_width - b.width) + b.height)
			b.r = 0.0
			b.g = 0.0
			b.b = 1.0

		


		#memory slaves
		for i in range (0, len(self.boxes["mslaves"])):
			b = self.boxes["mslaves"][i]
			b.width = column_width * self.box_width_ratio 
			b.height = b.width * self.mslave_height_ratio  
			b.x = (column_width - b.width) / 2.0 + (column_width * 3) 
			b.y = (column_width - b.width) / 2.0 + \
					i * ((column_width - b.width) + b.height) + \
					height / 2
			b.r = 1.0
			b.g = 0.0
			b.b = 1.0


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
			self.prev_ms_count != ms_count  or \
			self.recalculate:
			
			print "calculate"
			self.recalculate = False
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
		self.draw_moving()


	def draw_host_interface(self):	
		cr = self.cr
		b = self.boxes["host_interface"]

		self.draw_box(	b.x, b.y,
						b.width, b.height,
						text = "host interface",
						r = b.r, g = b.g, b = b.b,
						style = BOX_STYLE.OUTLINE)

	def draw_master(self):
		cr = self.cr
		b = self.boxes["master"]
		self.draw_box(	b.x, b.y,
						b.width, b.height,
						text = "master",
						r = b.r, g = b.g, b = b.b,
						style = BOX_STYLE.OUTLINE)


	def draw_mem_interconnect(self):
		cr = self.cr
		b = self.boxes["mic"]
		self.draw_box(	b.x, b.y,
						b.width, b.height,
						text = "memory ic",
						r = b.r, g = b.g, b = b.b,
						style = BOX_STYLE.OUTLINE)




	def draw_periph_interconnect(self):
		cr = self.cr
		b = self.boxes["pic"]
		self.draw_box(	b.x, b.y,
						b.width, b.height,
						text = "periph ic",
						r = b.r, g = b.g, b = b.b,
						style = BOX_STYLE.OUTLINE)


	def draw_periph_slaves(self):
		for i in range (0, len(self.boxes["pslaves"])):
			#if there is a box moving don't draw it here
			if self.moving and not (self.selected_node is None):
				if self.selected_node.slave_type == Slave_Type.peripheral\
					and self.selected_node.slave_index == i:
					continue

			name = self.sgm.get_slave_name_at(i, Slave_Type.peripheral)
			p = self.sgm.get_node(name)
			b = self.boxes["pslaves"][i]
			self.draw_box(	b.x, b.y,
							b.width, b.height,
							text = p.name,
							r = b.r, g = b.g, b = b.b,
							style = BOX_STYLE.OUTLINE)


	def draw_mem_slaves(self):
		for i in range (0, len(self.boxes["mslaves"])):
			#if there is a box moving don't draw it here
			if self.moving and not (self.selected_node is None):
				if self.selected_node.slave_type == Slave_Type.memory \
					and self.selected_node.slave_index == i:
					continue
			name = self.sgm.get_slave_name_at(i, Slave_Type.memory)
			p = self.sgm.get_node(name)
			b = self.boxes["mslaves"][i]
			self.draw_box(	b.x, b.y,
							b.width, b.height,
							text = p.name,
							r = b.r, g = b.g, b = b.b,
							style = BOX_STYLE.OUTLINE)

	def draw_moving(self):
		if self.moving == 0:
			return

		node = None
		b = None

		#draw trashcan
		b = self.boxes["trash"]
		self.draw_box(	b.x, b.y,
						b.width, b.height,
						text = "Trash",
						r = b.r, g = b.g, b = b.b,
						style = BOX_STYLE.OUTLINE)

		#draw the node
		node = self.selected_node
		if node.slave_type == Slave_Type.peripheral:
			b = self.boxes["pslaves"][node.slave_index]

		else:
			b = self.boxes["mslaves"][node.slave_index]
			
		self.mov_x = self.p_x - self.rel_x
		self.mov_y = self.p_y - self.rel_y

		self.draw_box(	self.mov_x, self.mov_y,
						b.width, b.height,
						text = node.name,
						r = b.r, g = b.g, b = b.b,
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
		


	def debug_line(self, debug_string):
		cr = self.cr
		cr.set_source_rgb(0, 0, 0)
		cr.move_to(5, self.dy)
		cr.show_text(debug_string)
		self.dy += 10

	def display_debug(self, width, height):
		self.dy = 10
		column_width = self.get_column_width(width)
		self.debug_line("debug")
		self.debug_line("width, height: " + \
							str(width) + ", " + str(height))
		self.debug_line("width, height: " + \
							str(width) + ", " + str(height))
		self.debug_line("column width: " + str(column_width))

		self.debug_line("peripheral slaves: " + str(self.prev_ps_count))
		self.debug_line("memory slaves: " + str(self.prev_ms_count))
		self.debug_line("pointer x: %6d" % self.p_x)
		self.debug_line("pointer y: %6d" % self.p_y)
		self.debug_line("moving: %6d" % self.moving)

		node_name = "None"
		if not (self.selected_node is None):
			node_name = self.selected_node.name

		self.debug_line("selected node: %s" % node_name )
		self.debug_line("new slave: %6d" % self.new_slave)


		



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
			if self.moving and not (self.selected_node is None):
				if self.selected_node.slave_type == Slave_Type.peripheral\
					and self.selected_node.slave_index == i:
					continue
			b = self.boxes["pslaves"][i]
			cr.move_to (pic_b.x + pic_b.width, \
						(column_width - b.width) / 2.0 + \
						i * ((column_width - b.width) + b.height) + \
						b.height / 2.0)

			cr.line_to (b.x, b.y + b.height / 2.0)

		#memory interconnect to memory slaves
		for i in range (0, len(self.boxes["mslaves"])):
			if self.moving and not (self.selected_node is None):
				if self.selected_node.slave_type == Slave_Type.memory \
					and self.selected_node.slave_index == i:
					continue
			b = self.boxes["mslaves"][i]
			cr.move_to (mic_b.x + mic_b.width, \
						(column_width - b.width) / 2.0 + \
						i * ((column_width - b.width) + b.height) + \
						b.height / 2.0 +\
						height / 2.0)

			cr.line_to (b.x, b.y + b.height / 2.0)



		cr.stroke()

	def get_selected_name(self, x, y):
		name = ""

		#check host interface
		b = self.boxes["host_interface"]
		if b.in_bounding_box(x, y):	
			#return the name
			name = gm.get_unique_name("Host Interface", Node_Type.host_interface)
		
		#check master
		b = self.boxes["master"]
		if b.in_bounding_box(x, y):	
			name = gm.get_unique_name("Master", Node_Type.master)

		#check memory interconnect
		b = self.boxes["mic"]
		if b.in_bounding_box(x, y):	
			name = gm.get_unique_name("Memory", Node_Type.memory_interconnect)



		#check peripheral interconnect
		b = self.boxes["pic"]
		if b.in_bounding_box(x, y):	
			name = gm.get_unique_name("Peripherals", Node_Type.peripheral_interconnect)



		#check the peripheral slaves
		for i in range (0, len(self.boxes["pslaves"])):
			pname = self.sgm.get_slave_name_at(i, Slave_Type.peripheral)
			b = self.boxes["pslaves"][i]
			if b.in_bounding_box(x, y):	
				name = pname


		#check the memory slaves
		for i in range (0, len(self.boxes["mslaves"])):
			mname = self.sgm.get_slave_name_at(i, Slave_Type.memory)
			b = self.boxes["mslaves"][i]
			if b.in_bounding_box(x, y):	
				name = mname

		return name




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

