#!/usr/bin/env python

import gtk
import gobject
import cairo

from gtk import gdk

#sap_gui.py

class sap_gui_controller:
	def __init__(self):
		"""
		Display the Sap GUI
		"""

		builderfile = "sap_gui.glade"
		windowname = "Sap IDE"
		builder = gtk.Builder()
		builder.add_from_file(builderfile)

		#register the callbacks
		builder.connect_signals(self)

		self.window = builder.get_object("main_window")
		self.drawing_area = builder.get_object("cairo_canvas")
		self.window.connect("destroy", gtk.main_quit)
		self.window.show()

		return


	def on_file_quit(self, widget):
		gtk.main_quit()


def run():
	app = sap_gui_controller()
	gtk.main()

if __name__ == "__main__":
	run()
			
