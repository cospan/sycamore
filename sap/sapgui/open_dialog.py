import gtk
import sap_controller
import status_text

class OpenDialog:
	def __init__(self):
		self.sc = sap_controller.SapController()
		builderfile = "open_dialog.glade"
		builder = gtk.Builder()
		builder.add_from_file(builderfile)
		
		self.open_dialog = builder.get_object("open_dialog")
		self.preview_tree = builder.get_object("preview_tree")
		model = gtk.ListStore(str, str)
		self.preview_tree.set_model(model)
		self.open_button = builder.get_object("open_button")
		self.cancel_button = builder.get_object("cancel_button")
		self.open_button.connect("clicked", self.on_open_clicked)
		self.cancel_button.connect("clicked", self.on_cancel_clicked)
		self.open_dialog.connect("selection-changed", self.on_file_changed)
		self.status = status_text.StatusText()
		self.filename = ""

	def get_filename(self):
		return self.filename

	def on_open_clicked(self, widget):
		self.filename = ""
		f = self.open_dialog.get_filenames()
		if len(f) == 0:
			self.status.print_warning(__file__, "No file selected")

		self.filename = f[0]
		self.status.print_info(__file__, "File %s open" % str(f[0]))
		self.hide()
		print "open clicked"

	def on_cancel_clicked(self, widget):
		self.filename = ""
		print "canceled"
		self.open_dialog.hide()

	def on_file_changed(self, widget):
		f = self.open_dialog.get_filenames()
		temp = ""
		if len(f) > 0:
			temp = f[0]
			self.setup_preview(temp)



	def hide(self):
		self.open_dialog.hide()

	def show(self):
		self.open_dialog.show()


	def setup_preview(self, filename):
		print "setting up preview"
		#attempt to load in the json file
		#reset the preview sap controller
		sc = self.sc
		sc.new_design()
		#load the design in the file
		try:
			sc.load_config_file(filename)
		except IOError as err:
			print "%s is not a config file" % filename
			return

		sc.initialize_graph()
		pt = self.preview_tree
		model = self.preview_tree.get_model()
		model.clear()

		#create the columns
		name_column = gtk.TreeViewColumn()
		name_column.set_title("Name")
		cell = gtk.CellRendererText()
		name_column.pack_start(cell, True)
		name_column.add_attribute(cell, "text", 0)

		property_column = gtk.TreeViewColumn()
		property_column.set_title("Property")
		cell = gtk.CellRendererText()
		property_column.pack_start(cell, True)
		property_column.add_attribute(cell, "text", 1)

		#add the columns if they are needed
		if pt.get_column(0) is None:
			pt.insert_column(name_column, 0)

		if pt.get_column(1) is None:
			pt.insert_column(property_column, 1)

		it = model.append()
		model.set(it, 0, "Name")
		model.set(it, 1, sc.get_project_name())

		it = model.append()
		model.set(it, 0, "Board")
		model.set(it, 1, sc.get_board_name())



		



