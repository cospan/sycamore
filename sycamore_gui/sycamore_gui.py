#!/usr/bin/env python

import gtk

#sycamore_gui.py


class sycamore_gui:
	def __init__(self):
		"""
		Display the main sycamore_window
		"""
		
		builderfile = "sycamore_view.glade"
		windowname = "Sycamore"
		builder = gtk.Builder()
		builder.add_from_file(builderfile)

		# register the callbacks
		builder.connect_signals(self)

		self.window = builder.get_object("main_window")
		self.window.connect("destroy", gtk.main_quit)
		self.window.show()
		return

	def on_miraclegrow_clicked(self, widget):
		print "miracle grow clicked"

	def on_sap_clicked(self, widget):
		print "sap clicked"

	def on_xylem_clicked(self, widget):
		print "xylem clicked"

	def on_main_window_destroy(self, widget):
		print "destroy"
		gtk.main_quit()

	def on_file_quit(self,wdiget):
		gtk.main_quit()
		

def run():
	app = sycamore_gui()
	gtk.main()

if __name__ == "__main__":
	run()
