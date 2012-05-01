#module_view.py
import gtk
import gobject
import cairo

from gtk.gdk  import Pixbuf

import os
import sys
import getopt 



class ModuleView:
	def __init__(self):
		builderfile = "module_view.glade"
		print "module view!"
		builder = gtk.Builder()
		builder.add_from_file(builderfile)

		#register the callbacks
		builder.connect_signals(self)


		self.module_icon = builder.get_object("module_icon")
		self.property_vbox = builder.get_object("property_vbox")
		self.port_table = builder.get_object("port_table")
		self.pin_table = builder.get_object("pin_table")
		self.connection_viewport = builder.get_object("connection_viewport")
		self.user_name = builder.get_object("label_user_name")
		self.module_name = builder.get_object("label_module_name")
		self.file_name = builder.get_object("label_file_name")
		self.window = builder.get_object("module_frame")
		self.window.show_all()


	def button_unbind_clicked_cb(self, widget):
		print "unbind"

	def button_bind_clicked_cb(self, widget):
		print "bind"





def main(argv):
	
	print "main main!"
	mv = ModuleView()
	gtk.main()

if __name__ == "__main__":
	main(sys.argv[1:])
	print "main!"
