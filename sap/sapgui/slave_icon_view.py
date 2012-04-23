import gtk
import gobject
import cairo

from gtk.gdk  import Pixbuf
from gtk import gdk


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
	icon_width = 128 
	icon_height = 64

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


class SlaveIconView(gtk.ScrolledWindow):
	def __init__(self):
		"""
		initialize
		"""

		super(SlaveIconView, self).__init__()
		from saplib import saputils

		self.icon_view = gtk.IconView()
		self.icon_view.show()
		self.add(self.icon_view)
		self.model = gtk.ListStore(Pixbuf, str)
		self.slave_dict = {}
		self.icon_view.set_pixbuf_column(0)

		self.icon_view.enable_model_drag_source( \
							gtk.gdk.BUTTON1_MASK, \
							[], \
							gtk.gdk.ACTION_COPY) 

		self.icon_view.connect("drag-data-get", self.on_drag_data_get)
		self.icon_view.connect("drag-begin", self.on_drag_begin) 

	def on_drag_begin(self, widget, drag_context):
		print "on drag begin"

	def on_drag_data_get(self, widget, drag_context, data, info, time):
		print "drag destination is requesting data"
		selected_path = self.icon_view.get_selected_items()[0]
		selected_iter = self.icon_view.get_model().get_iter(selected_path)
		#the pixbuf is in column 0
		print "info: " + str(info)

		if info == 0:
			print "found a pixbuf"
			#get the text that's associated with this drag item
			text = self.icon_view.get_model().get_value(selected_iter, 1)
			data.set_text(text, -1)


	def setup_slave_icon_model(self, slave_dict):
#		print "adding initial icon list"
		for name in slave_dict.keys():
			#get the slave module name
			r = slave_dict[name]["r"]
			g = slave_dict[name]["g"]
			b = slave_dict[name]["b"]
#			print "r, g, b: %f, %f, %f" % (r, g, b)
			pixbuf = setup_box(name, r, g, b)
			self.model.append([pixbuf, slave_dict[name]["filename"]])
#			self.model.append([pixbuf, name])
	

	def set_slave_list(self, slave_dict):
		self.model = gtk.ListStore(Pixbuf, str)
		self.slave_dict = slave_dict
		self.setup_slave_icon_model(slave_dict)
		self.icon_view.set_model(self.model)
		self.icon_view.drag_source_add_text_targets()
		
#		targets = gtk.TargetList.new([])
#		targets.add_image_targets(TARGET_ENTRY_PIXBUF, True)
#		self.icon_view.drag_source_set_target_list(targets)


		
	def get_slave_target_list(self):
		print "get target source"

