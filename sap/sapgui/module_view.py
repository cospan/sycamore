#module_view.py
import gtk
import gobject
import cairo

from gtk.gdk  import Pixbuf

import os
import sys
import getopt 

import saputils
from sap_gui_error import GUI_Error

import sap_graph_manager as sgm
import sap_controller as sc

from sap_graph_manager import Slave_Type
from sap_graph_manager import Node_Type

import status_text

class ModuleView:
	def __init__(self, sap_controller):
		builderfile = "module_view.glade"
		builder = gtk.Builder()
		builder.add_from_file(builderfile)
		self.sc = sap_controller

		#register the callbacks
		#builder.connect_signals(self)

		self.frame = builder.get_object("module_frame")


		self.module_icon = builder.get_object("module_icon")
		self.slave_prop_view = builder.get_object("hbox_prop_slave_view")
		self.property_vbox = gtk.VBox(False, 0)
		self.property_hbox = gtk.HBox(True, 0)
		self.property_vbox.add(self.property_hbox)
		self.property_label = gtk.Label("Properties")
		self.property_hbox.pack_start(self.property_label)
#		self.property_vbox = builder.get_object("property_vbox")
#		self.property_hbox = builder.get_object("property_hbox")
#		self.property_label = builder.get_object("label_properties")

		self.slave_prop_view.pack_end(self.property_vbox, True, False)

		self.connection_viewport = builder.get_object("connection_viewport")
		self.port_tree = builder.get_object("port_tree")
		self.pin_tree = builder.get_object("pin_tree")
		self.bind_tree = builder.get_object("bind_tree")

		#self.port_tree.connect("row-activated", self.on_port_selected)
		#self.pin_tree.connect("row-activated", self.on_pin_selected)
		#self.bind_tree.connect("row-activated", self.on_bind_selected)

		self.port_tree.connect("cursor-changed", self.on_port_selected)
		self.pin_tree.connect("cursor-changed", self.on_pin_selected)
		self.bind_tree.connect("cursor-changed", self.on_bind_selected)


		self.user_name = builder.get_object("label_user_name")
		self.module_name = builder.get_object("label_module_name")
		self.author = builder.get_object("label_author")
		self.email = builder.get_object("label_email")
		self.window = builder.get_object("module_frame")
		self.window.show_all()



		self.module_icon.connect ( "expose_event", self.mi_expose_event )
		bind_button = builder.get_object("button_bind")
		unbind_button = builder.get_object("button_unbind")

		bind_button.connect("clicked", self.on_bind_clicked)
		unbind_button.connect("clicked", self.on_unbind_clicked)

		self.s = status_text.StatusText()
		
		self.node = None
		self.mi_cr = None
		self.property_table = None
		self.property_dict = {}
		self.property_pos = 1
		self.txpad = 0
		self.typad = 0
		self.property_update_button = None
		self.property_update_callback = None
		self.bind_callback = None
		self.unbind_callback = None

		self.selected_port = None
		self.selected_pin = None
		self.selected_binding = None



	def setup(self, node):
		self.s.print_info(__file__, "%s loaded" % node.name)
		self.clear()

		if node is None:
			self.clear()
			return

		if self.property_table is not None:
			print "removing table"
			self.property_vbox.remove(self.property_table)
			self.property_table = None

		if self.property_update_button is not None:
			self.property_hbox.remove(self.property_update_button)
			self.property_update_button = None


		self.node = node
		#print str(node.parameters)

		#populate the text
		self.user_name.set_text(self.node.name)
		self.module_name.set_text(self.node.parameters["module"])
		self.author.set_text("not implemented")
		self.email.set_text("not implemented")

		#populate the image
		if self.node.node_type == Node_Type.host_interface:
			self.draw_icon(self.node.name, 0.0, 1.0, 0.0) 
		elif self.node.node_type == Node_Type.slave:
			if self.node.slave_type == Slave_Type.peripheral:
				self.draw_icon(self.node.name, 0.0, 0.0, 1.0)
			else:
				self.draw_icon(self.node.name, 1.0, 0.0, 1.0)

		#setup the properties view
		self.setup_property_view()

		self.setup_port_list()
		self.setup_pin_list()
		self.setup_bind_list()


	def on_port_selected(self, tree):
		itr = tree.get_selection().get_selected()[1]
		try:
			self.selected_port = tree.get_model().get_value(itr, 0)
		except:
			self.selected_port = None
		#print "port value: " + self.selected_port

	def on_pin_selected(self, tree):
		itr = tree.get_selection().get_selected()[1]
		try:
			self.selected_pin = tree.get_model().get_value(itr, 0)
		except:
			self.selected_pin = None
		#print "pin %s selected" % self.selected_pin

	def on_bind_selected(self, tree):
		itr = tree.get_selection().get_selected()[1]
		try:
			self.selected_binding = tree.get_model().get_value(itr, 0)
		except:
			self.selected_binding = None
		#print "bind %s selected" % self.selected_binding


	def on_bind_clicked(self, widget):
		#check if the port is selected
		if self.selected_port is None:
			self.s.print_error(__file__, "port has not been selected")
#			raise GUI_Error("port is not selected")

		#check if the pin is selected
		if self.selected_pin is None:
			self.s.print_error(__file__, "pin has not been selected")
#			raise GUI_Error("pin is not selected")

		#get the unique name of the module
		uname = self.node.unique_name

		self.bind_callback(uname, self.selected_port, self.selected_pin)
		self.selected_port = None
		self.selected_pin = None
		self.setup_bind_list()
	
	def on_unbind_clicked(self, widget):
		#print "unbind has been clicked"
		if self.selected_binding is None:
			self.s.print_error(__file__, "binding has not been selected")
#			raise GUI_Error("binding is not selected")

		#get the unique name of the module
		uname = self.node.unique_name

		self.unbind_callback(uname, self.selected_binding)
		self.selected_binding = None
		self.setup_bind_list()

	#setup the ports/pins/binding
	def setup_port_list(self):
		#print "setup port table"
		pt = self.port_tree
		pl = gtk.ListStore(str, str)
		pt.set_model(pl)
		pl.clear()

		#create the columns
		name_column = gtk.TreeViewColumn()
		name_column.set_title("Name")
		cell = gtk.CellRendererText()
		name_column.pack_start(cell, True)
		name_column.add_attribute(cell, "text", 0)

		dir_column = gtk.TreeViewColumn()
		dir_column.set_title("Direction")
		cell = gtk.CellRendererText()
		dir_column.pack_start(cell, True)
		dir_column.add_attribute(cell, "text", 1)


		#add the columns if they are needed
		if pt.get_column(0) is None:
			pt.insert_column(name_column, 0)

		if pt.get_column(1) is None:
			pt.insert_column(dir_column, 1)

		for c in pt.get_columns():
			print "columns: " + c.get_title()

		ports = self.node.parameters["ports"]
		ab_ms = self.node.parameters["arbitrator_masters"]
		for port in ports.keys():

			if port == "clk":
				continue
			if port == "rst":
				continue
			
			if port.partition("_")[0] == "wbs":
				continue

			pre = port.partition("_")[0]
			if pre in ab_ms:
				continue


			direction = ports[port]["direction"]
			#print "port: %s, direction: %s" % (port, direction)
			print "port[%s] = %s" % (port, str(ports[port]))
			#pl.append([port, direction])
			size = ports[port]["size"]

			if size == 1:
				it = pl.append()
				pl.set(it, 0, port)
				pl.set(it, 1, direction)

			else:
				min_value = 0
				max_value = 1
				if "min_val" in ports[port].keys():
					min_value = ports[port]["min_val"]
				if "max_val" in ports[port].keys():
					max_value = ports[port]["max_val"]

				for i in range(min_value, min_value + size):
					it = pl.append()
					p = port + str("[%d]" % i)
					pl.set(it, 0, p)
					pl.set(it, 1, direction)


					
				


	def setup_pin_list(self):
		print "setup pin list"
		pt = self.pin_tree
		pl = gtk.ListStore(str)
		pt.set_model(pl)
		pl.clear()

		#create the columns
		name_column = gtk.TreeViewColumn()
		name_column.set_title("Name")
		cell = gtk.CellRendererText()
		name_column.pack_start(cell, True)
		name_column.add_attribute(cell, "text", 0)

		#add the columns if they are needed
		if pt.get_column(0) is None:
			pt.insert_column(name_column, 0)

		#get a list of the nets in the constraint file
		files = self.sc.get_constraint_file_names()
		netnames = []
		for f in files:
			nn = saputils.get_net_names(f)	
			for n in nn:
				if n in netnames:
					continue
				netnames.append(n)

		
		#now I have a list of net names
		for net in netnames:
			if net == "clk":
				continue
			if net == "rst":
				continue

			it = pl.append()
			pl.set(it, 0, net)


	
	def setup_bind_list(self):
		print "setup bind table"
		bt = self.bind_tree
		bl = gtk.ListStore(str, str, str)
		bt.set_model(bl)
		bl.clear()

		#create the columns
		port_column = gtk.TreeViewColumn()
		port_column.set_title("Module Port")
		cell = gtk.CellRendererText()
		port_column.pack_start(cell, True)
		port_column.add_attribute(cell, "text", 0)

		pin_column = gtk.TreeViewColumn()
		pin_column.set_title("FPGA Pin")
		cell = gtk.CellRendererText()
		pin_column.pack_start(cell, True)
		pin_column.add_attribute(cell, "text", 1)

		dir_column = gtk.TreeViewColumn()
		dir_column.set_title("Direction")
		cell = gtk.CellRendererText()
		dir_column.pack_start(cell, True)
		dir_column.add_attribute(cell, "text", 2)

		#add the columns if they are needed
		if bt.get_column(0) is None:
			bt.insert_column(port_column, 0)

		if bt.get_column(1) is None:
			bt.insert_column(pin_column, 1)

		if bt.get_column(2) is None:
			bt.insert_column(dir_column, 2)

		bindings = self.node.bindings
		for port in bindings.keys():
			pin = bindings[port]["port"]
			direction = bindings[port]["direction"]

			it = bl.append()
			bl.set(it, 0, port)
			bl.set(it, 1, pin)
			bl.set(it, 2, direction)



	


	def setup_property_view(self):
	
		self.property_vbox = gtk.VBox(False, 0)
		self.property_hbox = gtk.HBox(True, 0)
		self.property_vbox.add(self.property_hbox)
		self.property_label = gtk.Label("Properties")
		self.property_hbox.pack_start(self.property_label)
#		self.property_vbox = builder.get_object("property_vbox")
#		self.property_hbox = builder.get_object("property_hbox")
#		self.property_label = builder.get_object("label_properties")

		self.slave_prop_view.pack_end(self.property_vbox, True, False)


#		if self.property_table is not None:
#			self.property_vbox.remove(self.property_table)

#		if self.node is None:
#			self.property_label.set_text("No Properties")
#			return

		keys = self.node.parameters.keys()
		if "parameters" not in keys:
			self.property_label.set_text("No Properties")
			self.property_vbox.show_all()
			return
		
		keys = self.node.parameters["parameters"].keys()
		if len(keys) == 0:
			self.property_label.set_text("No Properties")
			self.property_vbox.show_all()
			return

		print "setup property view"

		self.property_label.set_text("Properties")
		parameters = self.node.parameters["parameters"]
		self.property_table = gtk.Table(	rows = len(keys), 
											columns = 1, 
											homogeneous = True)

		table = self.property_table

		#go through the properties and set them up
		self.property_dict = {}
		for key in keys:
			value = parameters[key]
			self.set_property(key, value, True)	

		self.property_vbox.pack_end(table, True, False)

		self.property_update_button = gtk.Button(label="Update")
		self.property_hbox.pack_end(self.property_update_button, True, False)

		self.property_update_button.connect("clicked",
											self.on_property_update_callback)
		self.property_vbox.show_all()


	def set_on_bind_callback(self, bind_callback):
		self.bind_callback = bind_callback

	def set_on_unbind_callback(self, unbind_callback):
		self.unbind_callback = unbind_callback

	def set_on_update_callback(self, update_callback):
		self.property_update_callback = update_callback

	def on_property_update_callback(self, widget):
		properties = {}

		#pull the data from the table and put it in a key/value pair
		for key in self.property_dict.keys():
			properties[key] = self.property_dict[key].get_text() 
			self.property_update_callback(self.node.unique_name, properties)

	def set_property(self, name, value, editable):
		"""
		sets a name/value pair in the property_view
		and specifies if the name/value is editable
		"""
		#in the table add this value
		table = self.property_table

#		table.resize(self.property_pos + 1, 2)
		self.property_pos += 1
		label = gtk.Label(name)
		table.attach(	label,
							0,
							1,
							self.property_pos - 1,
							self.property_pos,
							xoptions = gtk.EXPAND | gtk.FILL,
							yoptions = gtk.EXPAND | gtk.FILL,
							xpadding = self.txpad,
							ypadding = self.typad)

		entry = gtk.Entry()
		self.property_dict[name] = entry
		entry.set_text(str(value))
		table.attach(	entry,
							1,
							2,
							self.property_pos - 1,
							self.property_pos,
							xoptions = gtk.EXPAND | gtk.FILL,
							yoptions = gtk.EXPAND | gtk.FILL,
							xpadding = self.txpad,
							ypadding = self.typad)



	def clear(self):
		self.node = None
		self.user_name.set_text("no module")
		self.module_name.set_text("no module")
		self.author.set_text("unknown")
		self.email.set_text("unknown")

		self.slave_prop_view.remove(self.property_vbox)
		

		if self.property_table is not None:
			self.property_vbox.remove(self.property_table)
			self.property_table = None

		if self.property_update_button is not None:
			self.property_hbox.remove(self.property_update_button)
			self.property_update_button = None

		self.property_pos = 1
		self.draw_icon("no module", 0.0, 0.0, 0.0)


	def mi_expose_event( self, widget, event ):
#		print "expose event"
		self.mi_cr = widget.window.cairo_create( )
		mi = self.module_icon
		alloc = mi.get_allocation()
		icon_width = alloc.width 
		icon_height = alloc.height
		self.mi_draw( icon_width, icon_height)


	def mi_draw(self, width, height):
		if self.node is None:
			draw_icon("no module", 0.0, 0.0, 0.0, width, height)
			return

		#populate the image
		if self.node.node_type == Node_Type.host_interface:
			self.draw_icon(self.node.name, 0.0, 1.0, 0.0, width, height) 
		elif self.node.node_type == Node_Type.slave:
			if self.node.slave_type == Slave_Type.peripheral:
				self.draw_icon(self.node.name, 0.0, 0.0, 1.0, width, height)
			else:
				self.draw_icon(self.node.name, 1.0, 0.0, 1.0, width, height)



	def draw_icon(self, name, r = 0.0, g = 0.0, b = 1.0, width = 0.0, height = 0.0):

		if self.mi_cr is None:
			return
		cr = self.mi_cr

		mi = self.module_icon
		#draw box with the color given
		cr.set_source_rgb(r, g, b)
		cr.rectangle(0, 0, width, height)
		cr.fill()
		#draw boarder
		cr.set_source_rgb(0.0, 0.0, 0.0)
		cr.rectangle(0, 0, width, height)
		cr.set_line_width(5.0)
		cr.stroke()
		#draw text
		cr.set_source_rgb(0.0, 0.0, 0.0)
		cr.set_font_size(10)
		x_b, y_b, twidth, theight = cr.text_extents(name)[:4]
		text_x = 0.5 - twidth / 2 - x_b
		text_y = 0.5 - theight / 2 - y_b

		pos_x = 0 + (width / 2.0) + text_x
		pos_y = 0 + (height / 2.0) + text_y
		cr.move_to(pos_x, pos_y)
		cr.show_text(name)



	def get_frame(self):
		return self.frame 





def main(argv):
	
	print "main main!"
	mv = ModuleView()
	gtk.main()

if __name__ == "__main__":
	main(sys.argv[1:])
	print "main!"
