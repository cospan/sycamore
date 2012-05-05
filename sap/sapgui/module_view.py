#module_view.py
import gtk
import gobject
import cairo

from gtk.gdk  import Pixbuf

import os
import sys
import getopt 

import sap_graph_manager as sgm
import sap_controller as sc

from sap_graph_manager import Slave_Type
from sap_graph_manager import Node_Type

class ModuleView:
	def __init__(self, sap_controller):
		builderfile = "module_view.glade"
		builder = gtk.Builder()
		builder.add_from_file(builderfile)
		self.sc = sap_controller

		#register the callbacks
		builder.connect_signals(self)

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

		self.port_table = builder.get_object("port_table")
		self.pin_table = builder.get_object("pin_table")
		self.connection_viewport = builder.get_object("connection_viewport")
		self.user_name = builder.get_object("label_user_name")
		self.module_name = builder.get_object("label_module_name")
		self.author = builder.get_object("label_author")
		self.email = builder.get_object("label_email")
		self.window = builder.get_object("module_frame")
		self.window.show_all()



		self.module_icon.connect ( "expose_event", self.mi_expose_event )
		self.node = None
		self.mi_cr = None
		self.property_table = None
		self.property_dict = {}
		self.property_pos = 1
		self.txpad = 0
		self.typad = 0
		self.property_update_button = None
		self.property_update_callback = None




	def button_unbind_clicked_cb(self, widget):
		print "unbind"

	def button_bind_clicked_cb(self, widget):
		print "bind"



	def setup(self, node):
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
