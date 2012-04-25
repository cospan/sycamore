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
		import property_view as pv

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
		self.gd.set_slave_select_callback(self.on_slave_selected)

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


#slave icon view and property view
		self.slave_icon_view = siv.SlaveIconView()
		#self.slave_icon_view.show()
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
		self.slave_icon_view.set_size_request(-1, 300)
		self.slave_icon_view.set_slave_icon_selected_callback(self.on_slave_icon_selected)
	
#slave icon view
		self.prop_slave_view.add1(self.slave_icon_view)
		self.property_view = pv.PropertyView()
		self.property_view.show_all()
		self.property_view.set_size_request(-1, 100)


		self.prop_slave_view.add2(self.property_view)
		self.prop_slave_view.set_size_request(200, -1)
		self.prop_slave_view.show_all()

		#add the graph drawer and property/slave list to the graph_pane
		self.graph_pane.add1(self.gd)

		self.graph_pane.add2(self.prop_slave_view)

		self.window.connect("destroy", gtk.main_quit)
		self.window.show()
		return


	def on_slave_icon_selected(self, filename):
		"""
		whenever a user selects a slave in the slave icon view
		"""

		from saplib import saputils
		from saplib import sapfile
		sf = sapfile.SapFile()

		#add the slave into the slave graph
		bus_type = self.sc.get_bus_type()
		
		tags = saputils.get_module_tags(filename, bus_type)
		module_name = tags["module"]
		filename = sf.find_module_filename(module_name) 
		self.property_view.set_node(module_name, filename,  tags)

	def on_slave_selected(self, name, tags):
		"""
		whenever a user selects a slave from the actual graph
		update the options in the property box
		"""
		if name is None:
			self.property_view.clear_properties()
			return

		from saplib import saputils
		from saplib import sapfile
		sf = sapfile.SapFile()

		filename = None
		if "module" in tags.keys():
			module_name = tags["module"]
			filename = sf.find_module_filename(module_name) 
			bus_type = self.sc.get_bus_type()

		
		self.property_view.set_node(name, filename, tags)
		

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
			
