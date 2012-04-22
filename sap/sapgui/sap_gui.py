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

		import sap_controller as sc
		import graph_drawer
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

#slave icon view and property view
		self.graph_pane = gtk.HPaned()
		self.graph_pane.show()

		self.main_view.add(self.graph_pane)

		self.prop_slave_view = gtk.VPaned()
		self.prop_slave_view.set_size_request(200, -1)
		self.prop_slave_view.show()


		#create an icon view and model for it 
		self.slave_icon_view = gtk.IconView()
		self.slave_icon_view.show()

		#setup the icon model
		self.slave_list = gtk.ListStore(Pixbuf, str)
#		self.slave_list.set_selection_mode(
		self.setup_slave_icon_model(self.slave_list)
		self.slave_icon_view.set_model(self.slave_list)

		self.prop_slave_view.add1(self.slave_icon_view)

		#add the graph drawer and property/slave list to the graph_pane
		self.graph_pane.add1(self.gd)
		self.graph_pane.add2(self.prop_slave_view)






#		self.main_view.add2(self.gd)

		self.window.connect("destroy", gtk.main_quit)
		self.window.show()
		return

	def on_slave_add(self, node, slave_type, index):
		"""
		when a user visually drops a slave box into a valid location
		in one of the slave buses this gets called
		"""
		print "entered on slave add"

		#add the slave into the slave graph
		self.sc.add_slave(node.name, slave_type, index) 
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

		self.slave_icon_view.set_pixbuf_column(0)
		self.slave_icon_view.set_text_column(1)
		
		pixbuf = gtk.gdk.pixbuf_new_from_file_at_size("./images/slave_icon.png", 64, 128)

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
			
