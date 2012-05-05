import gtk
import gobject
import cairo

from gtk.gdk  import Pixbuf
from gtk import gdk

import sap_controller
import sap_graph_manager

from sap_graph_manager import Node_Type
from sap_graph_manager import Slave_Type



"""
Thanks to Osmo Maatta post in a forums that helped me
get a cairo image into a pixbuf
"""

def COLOR16_TO_CAIRO(x):
	return ((x) * (1.00 / 0xFFFF))

def setup_box(name, r = 0.0, g = 0.0, b = 1.0):
	"""
	does all the heavy lifting of setting up a box in a pix buffer
	"""
	color_depth = 8
	icon_width = 10 
	icon_height = 10

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

	cr.set_source_rgba(	COLOR16_TO_CAIRO(b * 0xFFFF), \
						COLOR16_TO_CAIRO(g * 0xFFFF), \
						COLOR16_TO_CAIRO(r * 0xFFFF), \
						1.0) # alpha = 1.0
	cr.rectangle(0, 0, icon_width, icon_height)
	cr.fill()
	cr.set_source_rgb(0.0, 0.0, 0.0)
	cr.rectangle(0, 0, icon_width, icon_height)
	cr.set_line_width(5.0)
	cr.stroke()

	cr.set_source_rgba(0.0, 0.0, 0.0, 1.0)
	cr.set_font_size(10)


	x_bearing, y_bearing, twidth, theight = cr.text_extents(name)[:4]
	text_x = 0.5 - twidth / 2 - x_bearing
	text_y = 0.5 - theight / 2 - y_bearing

	pos_x = 0 + (icon_width / 2.0) + text_x
	pos_y = 0 + (icon_height / 2.0) + text_y
	cr.move_to(pos_x, pos_y)
	cr.show_text(name)
	surface.flush()
	surface.finish()

	return pixbuf



class ProjectView(gtk.ScrolledWindow):

	def __init__(self, sc):
		super(ProjectView, self).__init__()
		
		self.sc = sc
		self.sgm = sc.get_graph_manager()

		self.model = None

		#setup the visual components
		self.project_tree = gtk.TreeView()

#		self.set_size_request(200, -1)

		self.setup_project_view()
		self.add(self.project_tree)
		self.project_item_selected_callback = None
		self.project_tree.connect("row-activated", self.on_item_change)

	def set_project_item_callback(self, project_item_callback):
		self.project_item_selected_callback = project_item_callback

	def on_item_change(self, widget, path, view_column): 
		"""whenever an item is activated"""
		#print "item changed to: " + str(path)
		item = self.model[path]
		itr = self.model.get_iter(path)
		text = self.model.get_value(itr, 2)
		#print "text: " + str(text)
		if self.project_item_selected_callback is not None:
			self.project_item_selected_callback(text)

	def setup_project_view(self):
		"""
		generate all the nodes
		"""
		self.project_column = gtk.TreeViewColumn()
		self.project_column.set_title("Project Tree")
		cell = gtk.CellRendererText()
		self.project_column.pack_start(cell, True)
		self.project_column.add_attribute(cell, "text", 0)

		self.project_image_column = gtk.TreeViewColumn()
		self.project_image_column.set_title("Modules")
		cell = gtk.CellRendererPixbuf()
		self.project_image_column.pack_start(cell, True)
		self.project_image_column.add_attribute(cell, "image", 1)



		self.model = gtk.TreeStore(str, gtk.gdk.Pixbuf, str)
		#insert the root node
		name = self.sc.get_project_name()
		pixbuf = setup_box(name, 1.0, 1.0, 1.0)
		it = self.model.append(None, [name, pixbuf, "base"])

		#insert the project Properties View
		name = "Project"
		pixbuf = setup_box(name, 1.0, 1.0, 1.0)
		self.model.append(it, [name, pixbuf, "project"])

		#insert the bus view
		name = "Bus"
		pixbuf = setup_box(name, 1.0, 1.0, 1.0)
		bit = self.model.append(it, [name, pixbuf, "bus"])

		#insert the host interface
		name = "Host Interface"
#		un = self.sgm.get_host_interface_node().unique_name
		pixbuf = setup_box(name, 0.0, 1.0, 0.0)
		self.model.append(bit, [name, pixbuf, "host_interface"])

		#insert the master
		name = "Master"
		pixbuf = setup_box(name, 1.0, 1.0, 0.0)
		mstr_it = self.model.append(bit, [name, pixbuf, "master"])

		#insert the peripheral bus
		name = "Peripherals"
		pixbuf = setup_box(name, 0.5, 1.0, 0.0)
		pit = self.model.append(mstr_it, [name, pixbuf, "peripherals"])

		#insert the memory bus
		name = "Memory"
		pixbuf = setup_box(name, 0.5, 1.0, 0.0)
		mit = self.model.append(mstr_it, [name, pixbuf, "memory"])

		ps_count = self.sgm.get_number_of_slaves(Slave_Type.peripheral)
		ms_count = self.sgm.get_number_of_slaves(Slave_Type.memory)


		#append the peripheral slaves
		for i in range (0, ps_count):
			node = self.sgm.get_slave_at(i, Slave_Type.peripheral)
			un = self.sgm.get_slave_name_at(i, Slave_Type.peripheral)
			pixbuf = setup_box(node.name, 0.0, 0.0, 1.0)
			self.model.append(pit, [node.name, pixbuf, un])

		for i in range (0, ms_count):
			node = self.sgm.get_slave_at(i, Slave_Type.memory)
			un = self.sgm.get_slave_name_at(i, Slave_Type.memory)
			pixbuf = setup_box(node.name, 1.0, 0.0, 1.0)
			self.model.append(mit, [node.name, pixbuf, un])

	
		if self.project_tree.get_column(0) is None:
			self.project_tree.append_column(self.project_column)

#		if self.project_tree.get_column(1) is None:
#			self.project_tree.insert_column(self.project_image_column, 1)

		self.project_tree.set_model(self.model)

		self.project_tree.expand_all()


