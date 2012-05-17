import gtk
import sap_controller
import status_text

class SaveDialog:
	def __init__(self):
		builderfile = "save_dialog.glade"
		builder = gtk.Builder()
		builder.add_from_file(builderfile)

		self.save_dialog = builder.get_object("save_dialog")
		self.save_button = builder.get_object("save_button")
		self.cancel_button = builder.get_object("cancel_button")

		self.save_button.connect("clicked", self.on_save_clicked)
		self.cancel_button.connect("clicked", self.on_cancel_clicked)
		
		self.status = status_text.StatusText()
		self.filename = ""

	def show(self):
		self.save_dialog.show()

	def on_save_clicked(self, widget):
		f = self.save_dialog.get_filenames()
		if len(f) == 0:
			self.status.print_warning(__file__, "No file selected")
			return

		self.filename = f[0]
		self.status.print_info(__file__, "Saving %s" % str(self.filename))
		self.save_dialog.hide()

	def on_cancel_clicked(self, widget):
		self.save_dialog.hide()
