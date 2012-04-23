#!/usr/bin/env python

import gtk
import gobject
import cairo

from gtk.gdk  import Pixbuf

import os
import sys
import getopt 

#sap_gui.py

_debug = False
_test_view = False


def usage():
	"""prints out message for the user"""
	print ""
	print "usage: sap_gui.py [options] [file_name]"
	print ""
	print "-d\t--debug\t:enable the global debug flag"
	print "-v\t--test_view\t:tests the view with a given file input"
	print "-h\t--help\t:prints out this message"
	print ""
	print ""
	print "Example:"
	print "Test the view with arb_example.json config file"
	print "sap_gui.py -v ../saplib/example_projects/arb_example.json"
	print ""



class SapGuiController:
	def __init__(self, filename = ""):
		"""
		Display the Sap GUI
		"""

		os.environ["SAPLIB_BASE"] = sys.path[0] + "/../saplib"
		from saplib import saputils
		import sap_controller as sc
		import graph_drawer
		import slave_icon_view as siv

		#load the sap controller
		self.sc = sc.SapController()

		try:
			if len(filename) > 0:
				print "loading: " + filename
				self.sc.load_config_file(filename)

		except IOError as err:
			print "Error loading file: " + str(err)

		self.sc.initialize_graph()

		self.gd = graph_drawer.GraphDrawer(self.sc.get_graph_manager())
		self.gd.set_debug_mode(debug = _debug)
		self.gd.set_slave_add_callback(self.on_slave_add)
		self.gd.set_slave_move_callback(self.on_slave_move)
		self.gd.set_slave_remove_callback(self.on_slave_remove)

		builderfile = "sap_gui.glade"
		windowname = "Sap IDE"
		builder = gtk.Builder()
		builder.add_from_file(builderfile)

		#register the callbacks
		builder.connect_signals(self)

		self.window = builder.get_object("main_window")
		self.main_view = builder.get_object("mainhpanel") 


		self.project_view = builder.get_object("project_view")
		self.project_view.set_size_request(150, 200)
		self.gd.set_size_request(400, 200)
		self.gd.show()

		self.graph_pane = gtk.HPaned()
		self.graph_pane.show()

		self.main_view.add(self.graph_pane)

		self.prop_slave_view = gtk.VPaned()
		self.prop_slave_view.set_size_request(200, -1)
		self.prop_slave_view.show()


#slave icon view and property view
		self.slave_icon_view = siv.SlaveIconView()
		self.slave_icon_view.show()
		bus_type = self.sc.get_bus_type()
		slave_file_list = saputils.get_slave_list(bus_type)	
		slave_dict = {}
		for slave in slave_file_list:
			slave_tags = saputils.get_module_tags(slave, bus_type)
			name = slave_tags["module"]
			slave_dict[name] = {}
			slave_dict[name]["filename"] = slave
			slave_dict[name]["r"] = 0.0
			slave_dict[name]["g"] = 0.0
			slave_dict[name]["b"] = 1.0
			

		self.slave_icon_view.set_slave_list(slave_dict)
	
#slave icon view
		self.prop_slave_view.add1(self.slave_icon_view)

		#add the graph drawer and property/slave list to the graph_pane
		self.graph_pane.add1(self.gd)
		self.graph_pane.add2(self.prop_slave_view)

		self.window.connect("destroy", gtk.main_quit)
		self.window.show()
		return


	def on_slave_add(self, filename, slave_type, index):
		"""
		when a user visually drops a slave box into a valid location
		in one of the slave buses this gets called
		"""
		print "entered on slave add"
		from saplib import saputils
		from sap_controller import Slave_Type

		print "filename: " + filename
		

		#add the slave into the slave graph
		bus_type = self.sc.get_bus_type()
		
		tags = saputils.get_module_tags(filename, bus_type)
		name_index = 0
		name = tags["module"] 

		p_count = self.sc.get_number_of_slaves(Slave_Type.peripheral)
		m_count = self.sc.get_number_of_slaves(Slave_Type.memory)
		#check peripheral bus for the name
		done = False
		while not done:
			print "checking names"
			for i in range (0, p_count):
				sname = self.sc.get_slave_name(Slave_Type.peripheral, i) 
				if sname == name + str(name_index): 
					name_index += 1
					continue

			for i in range (0, m_count):
				sname = self.sc.get_slave_name(Slave_Type.memory, i)
				if sname == name + str(name_index):
					name_index += 1
					continue
			done = True





		

		self.sc.add_slave(name + str(name_index), filename, slave_type, index) 
		self.gd.force_update()
		return True

	def on_slave_remove(self, slave_type, index):
		"""
		when a user visually removes a slave box
		"""
		print "entered on slave remove"
		#remove the slave from the slave graph
		self.sc.remove_slave(slave_type, index)
		self.gd.force_update()
		return True

	def on_slave_move(	self, 
						from_type, 
						from_index, 
						to_type, 
						to_index):
		"""
		when a previously existing slave is moved
		"""
		print "entered on_slave_move"
		if from_type == to_type and from_index == to_index:
			return False

		name = self.sc.get_slave_name(from_type, from_index)
		self.sc.move_slave(
							name,
							from_type,
							from_index,
							to_type,
							to_index)

		self.gd.force_update()
		return True


	def setup_slave_icon_model(self, ic_model):

		color_depth = 8
		icon_width = 128 
		icon_height = 64

		self.slave_icon_view.set_pixbuf_column(0)
		self.slave_icon_view.set_text_column(1)
		
		pixbuf = Pixbuf(	gtk.gdk.COLORSPACE_RGB, #color space
							True,					#has alpha
							color_depth,			#color depth
							icon_width,				#width
							icon_height)			#height

		#pixbuf = gtk.gdk.pixbuf_new_from_file_at_size("./images/slave_icon.png", 64, 128)

		pix_data = pixbuf.get_pixels_array()
		surface = cairo.ImageSurface.create_for_data(\
								pix_data, \
								cairo.FORMAT_RGB24, \
								pixbuf.get_width(), \
								pixbuf.get_height(), \
								pixbuf.get_rowstride())

		color = gtk.gdk.Color(0x0000, 0x0000, 0xFFFF) # Blue
		cr = cairo.Context(surface)
		cr.set_operator(cairo.OPERATOR_OVER)

		cr.set_source_rgba(	COLOR16_TO_CAIRO(color.blue), \
							COLOR16_TO_CAIRO(color.green), \
							COLOR16_TO_CAIRO(color.red), \
							1.0) # alpha = 1.0
		cr.rectangle(0, 0, icon_width, icon_height)
		cr.fill()
		cr.set_source_rgb(0.0, 0.0, 0.0)
		cr.rectangle(0, 0, icon_width, icon_height)
		cr.set_line_width(5.0)
		cr.stroke()

		cr.set_source_rgba(0.0, 0.0, 0.0, 1.0)
		cr.set_font_size(10)

		text = "test"

		x_bearing, y_bearing, twidth, theight = cr.text_extents(text)[:4]
		text_x = 0.5 - twidth / 2 - x_bearing
		text_y = 0.5 - theight / 2 - y_bearing

		pos_x = 0 + (icon_width / 2.0) + text_x
		pos_y = 0 + (icon_height / 2.0) + text_y
		cr.move_to(pos_x, pos_y)
		cr.show_text(text)
		surface.flush()
		surface.finish()



		print "adding initial icon list"
		ic_model.append([pixbuf, "hi"])	
		ic_model.append([pixbuf, "sup"])	
		




	def on_file_quit(self, widget):
		gtk.main_quit()


def main(argv):
	os.environ["SAPLIB_BASE"] = sys.path[0] + "/../saplib"
	sys.path.append(sys.path[0] + "/..")
	sys.path.append(sys.path[0] + "/../saplib")
	sys.path.append(sys.path[0] + '/../saplib/gen_scripts')

#	print "sys.path: " + str(sys.path)


	global _debug
	_debug = False
	global _test_view
	_test_view = False


	if (len(argv) > 0):
		try:
			opts, args = getopt.getopt(argv, "hdv:", ["help", "debug", "test_view"])
		except getopt.GetoptError, err:
			print (err)
			usage()
			sys.exit(2)

		for opt, arg in opts:
			if opt in ("-h", "--help"):
				usage()
				sys.exit()
			elif opt in ("-v", "--test_view"):
				print "Testing view"
				filename = arg
				_test_view = True
				print "File to load: " + filename
			elif opt in ("-d", "--debug"):
				print "Debug flag enabled"
				_debug = True
			else:
				print "unrecognized command: " + str(opt)
				usage()
				

	app = SapGuiController(filename)
	gtk.main()



if __name__ == "__main__":
	main(sys.argv[1:])
			
