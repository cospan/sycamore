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
		import project_view
		import project_properties_view as ppv
		import module_view
		import status_text
		import open_dialog
		import save_dialog
		import properties_dialog

		#load the sap controller
		self.sc = sc.SapController()
		self.module_view = module_view.ModuleView(self.sc)
		self.module_view.set_on_update_callback(self.on_properties_update)
		self.module_view.set_on_bind_callback(self.on_bind)
		self.module_view.set_on_unbind_callback(self.on_unbind)

		self.ppv = ppv.ProjectPropertiesView(self.sc)
		self.ppv.set_project_name_change_callback(self.on_project_name_changed)
		self.ppv.set_vendor_tool_change_callback(self.on_vendor_tools_changed)
		self.ppv.set_bus_change_callback(self.on_bus_template_changed)
		self.ppv.set_board_change_callback(self.on_board_changed)
		self.ppv.set_constraint_change_callback(self.on_constraint_file_change)
		self.open_dialog = open_dialog.OpenDialog()
		self.open_dialog.set_open_callback(self.on_open_cb)
		self.save_dialog = save_dialog.SaveDialog()
		self.save_dialog.set_slave_callback(self.on_save_cb)
		self.properties_dialog = properties_dialog.PropertiesDialog()

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
		self.gd.set_slave_arbitrator_select_callback(self.on_arbitrator_master_selected)
		self.gd.set_back_selected(self.on_back_selected)
		self.gd.set_arb_connect(self.on_arbitrator_connected)
		self.gd.set_arb_disconnect(self.on_arbitrator_disconnect)



		builderfile = "sap_gui.glade"
		windowname = "Sap IDE"
		builder = gtk.Builder()
		builder.add_from_file(builderfile)

		#register the callbacks
		builder.connect_signals(self)

		self.window = builder.get_object("main_window")
		self.main_view = builder.get_object("mainhpanel") 
		
		#instantiate the singleton
		sv = builder.get_object("status_textview")
		self.status = status_text.StatusText(sv) 
#		self.status.set_print_level(3)
		self.status.print_verbose(__file__, "Sap GUI Started!")

		self.current_widget = None

		#add the project view
		self.project_view = project_view.ProjectView(self.sc)
		self.project_view.set_size_request(200, -1)

		self.project_view.set_project_item_callback(self.on_project_item_changed)
		self.main_view.pack1(self.project_view, True, False)
		self.project_view.show()
		self.main_view.show_all()

		self.graph_pane = gtk.HPaned()
		self.graph_pane.show()
		self.set_main_view(self.graph_pane)
		#self.main_view.pack2(self.graph_pane, True, False)
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
#		self.graph_pane.add1(self.gd)
		self.graph_pane.pack1(self.gd, True, False)
		self.gd.set_size_request(400, -1)
		self.gd.show()
		self.graph_pane.pack2(self.prop_slave_view, True, False)

		#setup the toolbar
		self.main_toolbar = builder.get_object("main_toolbar")
		tb = self.main_toolbar

		#open
		icon = gtk.image_new_from_stock(gtk.STOCK_OPEN, 1)
		tb.append_item(
						"Open",					#label
						"Open a config file",	#tooltip
						"Open a config file",	#private tooltip
						icon,					#icon
						self.on_open)			#callback

		#save
		icon = gtk.image_new_from_stock(gtk.STOCK_SAVE, 1)
		tb.append_item(
						"Save",					#label
						"Save a config file",	#tooltip
						"Save a config file",	#private tooltip
						icon,					#icon
						self.on_save)			#callback

		#properties
		icon = gtk.image_new_from_stock(gtk.STOCK_PROPERTIES, 1)
		tb.append_item(
						"Properties",			#label
						"Set Properties",		#tooltip
						"Set Properties",		#private tooltip
						icon,					#icon
						self.on_properties)		#callback

		#execute
		icon = gtk.image_new_from_stock(gtk.STOCK_EXECUTE, 1)
		tb.append_item(
						"Execute",				#label
						"Set Execute",			#tooltip
						"Set Execute",			#private tooltip
						icon,					#icon
						self.on_execute)		#callback


		self.window.connect("destroy", gtk.main_quit)
		self.window.show()
		return

	def set_main_view(self, widget):
		if self.current_widget != None:
			self.main_view.remove(self.current_widget)
		self.main_view.pack2(widget, True, False)
		self.current_widget = widget

	def on_project_name_changed(self, project_name):
		"""
		project name has changed
		"""
		self.sc.set_project_name(project_name)
		self.ppv.setup()

	def on_vendor_tools_changed(self, vendor_tool_name):
		"""
		user changed the vendor tools
		"""
		print "not implemented yet!"
		self.status.print_error(__file__, "setting vendor tool is not implemented yet")
		self.ppv.setup()

	def on_bus_template_changed(self, bus_template_name):
		"""
		user chagned the bus template
		"""
		self.sc.set_bus_type(bus_template_name)
		self.ppv.setup()
	
	def on_board_changed(self, board_name):
		"""
		user selected a different board
		"""
		self.set_board_name(board_name)
		self.ppv.setup()

	def on_constraint_file_change(self, constraint_file, enable):
		"""
		user enabled or disabled a constraint file
		"""
		if enable:
			self.sc.add_project_constraint_file(constraint_file)
		else:
			self.sc.remove_project_constraint_file(constraint_file)

		self.ppv.setup()

	def on_project_item_changed(self, project_text):
		#print "project text: " + str(project_text)
		if project_text == "project":
			print "Project selected"
			self.setup_project_panel_view()
		elif project_text == "bus":
			print "Bus selected"
			self.setup_bus_view()
		elif project_text == "host_interface":
			print "host interface selected"
		elif project_text == "master":
			print "Master selected"
		elif project_text == "peripherals":
			print "Peripheral bus selected"
		elif project_text == "memory":
			print "Memory bus selected"
		else:
			print "Slave selected: " + str(project_text)
			self.setup_module_view(project_text)

	def setup_project_panel_view(self):
		print "setup the project panel"
		self.ppv.setup()
		self.set_main_view(self.ppv.get_frame())

	def setup_project_properties_view(self):
		print "setup the project properties view"

	def setup_bus_view(self):
		print "setup the bus view"
		self.set_main_view(self.graph_pane)
		#set the module view as the main view
		

	def setup_module_view(self, module_name):
		print "setup the module view"
		gm = self.sc.get_graph_manager()
		current_node = gm.get_node(module_name)
		
		self.module_view.setup(current_node)
		self.set_main_view(self.module_view.get_frame())
#		alloc = self.main_view.get_allocation()
#		rect = gtk.gdk.Rectangle (	0, \
#									0, \
#									alloc.width, \
#									alloc.height )
#		self.main_view.invalidate_rect ( rect, True )        


	def on_properties_update(self, unique_name, properties):
		print "property update callback"
		gm = self.sc.get_graph_manager()
		node = gm.get_node(unique_name)
		np = node.parameters["parameters"]

		#go through all the properties
		for key in properties.keys():
			np[key] = properties[key]

	def on_bind(self, unique_name, port, pin):
		from saplib.saperror import SlaveError 
		try:
			self.sc.set_binding(unique_name, port, pin)
		except SlaveError as se:
			self.status.print_error(__file__, "binding failed")
			return
			#self.status.print_error(__file__, str(se))

		self.status.print_info(__file__, "%s is bound to %s" % (port, pin))

	def on_unbind(self, unique_name, port):
		from saplib.saperror import SlaveError 
		try:
			self.sc.unbind_port(unique_name, port)
		except SlaveError as se:
			self.status.print_error(__file__, str(se))

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

	def on_arbitrator_connected(	self,
									host_name,
									arb_master,
									slave_name):
		"""
		called when a user connects an arbitrator bus to a slave
		"""
		current_slave = self.sc.get_connected_arbitrator_slave(host_name, arb_master)
		if current_slave is not None and current_slave != slave_name:
			#disconnect previous slave
			self.sc.remove_arbitrator_by_name(host_name, current_slave)

		self.sc.add_arbitrator_by_name (host_name, arb_master, slave_name)
		self.gd.set_arbitrator_view(	slave_name,
										arb_master,
										slave_name,
										True)


		self.gd.force_update()


	def on_arbitrator_disconnect(self, slave_name, arb_master):
		"""
		called when a user disconnects an arbitrator bus
		"""
		self.sc.remove_arbitrator_by_arb_master(slave_name, arb_master)
		self.gd.set_arbitrator_view(	slave_name,
										arb_master,
										"",
										True)

		self.gd.force_update()




	def on_arbitrator_master_selected(self, slave_name, arb_master, connected_slave):
		"""
		whenever a user selects an arbitrator master within a slave
		change the view to the arbitrator view
		"""

		#print "%s of %s selectd is connected to %s" % (arb_master, slave_name, connected_slave)

		self.gd.set_arbitrator_view(	slave_name,
										arb_master,
										connected_slave,
										True)
		self.gd.force_update()

	def on_back_selected(self):
		self.gd.set_arbitrator_view(	"",
										"",
										"",
										False)
		self.gd.force_update()

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
		#print "entered on slave add"
		from saplib import saputils
		from sap_controller import Slave_Type

		#print "filename: " + filename
		

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
			#print "checking names"
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
		self.project_view.setup_project_view()
		return True

	def on_slave_remove(self, slave_type, index):
		"""
		when a user visually removes a slave box
		"""
		#print "entered on slave remove"
		#remove the slave from the slave graph
		self.sc.remove_slave(slave_type, index)
		self.gd.force_update()
		self.project_view.setup_project_view()
		return True

	def on_slave_move(	self, 
						from_type, 
						from_index, 
						to_type, 
						to_index):
		"""
		when a previously existing slave is moved
		"""
		#print "entered on_slave_move"
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
		self.project_view.setup_project_view()
		return True

	def on_file_quit(self, widget):
		gtk.main_quit()

	def on_open(self, widget):
		"""
		opens up a file
		"""
		self.open_dialog.show()
		
	def on_open_cb(self, filename):
		print "openning a file"
		filename = self.open_dialog.get_filename()
		try:
			if len(filename) > 0:
				print "loading: " + filename
				self.sc.load_config_file(filename)

		except IOError as err:
			print "Error loading file: " + str(err)
			return

		self.sc.initialize_graph()
		self.gd.force_update()
		self.setup_bus_view()
		self.project_view.setup_project_view()
		#self.ppv.setup()


	def on_save(self, widget):
		"""
		saves a file
		"""
		self.save_dialog.show()

	def on_save_cb(self, filename):
		print "saving file %s" % filename
		self.sc.save_config_file(filename)

	def on_execute(self, widget):
		"""
		starts execution
		"""
		print "play pressed"

	def on_properties(self, widget):
		"""
		edits sapgui properties
		"""
		print "properties pressed"
		self.properties_dialog.show()



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
			
