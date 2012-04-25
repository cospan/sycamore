import gtk
import gobject
from sap_graph_manager import Node_Type
from sap_graph_manager import Slave_Type


class PropertyView(gtk.Frame):
	def __init__(self):
		super (PropertyView, self).__init__()
		
		self.set_label("Properties")

		self.txpad = 0
		self.typad = 0

		self.vbox = gtk.VBox(False, 3)
		self.add(self.vbox)
		self.vbox.show()

		#slave name
		self.node_label = gtk.Label("No Node")
		self.node_label.show()
		self.vbox.pack_start(	self.node_label, 
								expand = False,
								fill = True,
								padding = self.txpad)
		#separator
		sep = gtk.HSeparator()
		self.vbox.pack_start(	sep,
								expand = False,
								fill = True,
								padding = 0)

		
		self.module_pos			= 0
		self.filename_pos		= 1
		self.pos				= 2


		#table of parameters
		self.table = None
		self.initialize_table()

		self.update_button = gtk.Button(label="Upate")
		self.vbox.pack_end(			self.update_button,
								expand = False,
								fill = True,
								padding = 0)

		self.update_callback = None


	def set_on_update_callback(self, update_callback):
		self.update_callback = update_callback

	def on_update_click(self, widget):
		"""
		user updated the parameters
		"""
#		if self.update_callback is not None:
#			self.update_callback(	self.slave_name,
#									self.parameters)
									


		
	def set_node(self, name = "", filename = "", tags = {}):
		"""
		clears previous slave properties and sets the initial values 
		"""
		self.parameters = tags
		
		self.clear_properties()
		self.set_node_name(name)

		if filename is None:
			filename = "No Filename"

		self.set_file_name(filename)

		if "module" in self.parameters.keys():
			module_name = self.parameters["module"]
			self.set_module_name(module_name)

		
		if "parameters" in self.parameters.keys():
			keys = self.parameters["parameters"].keys()
			for key in keys:
				value = self.parameters["parameters"][key]
				self.set_property(key, value, True)	

		self.show_all()

	def clear_properties(self):
		"""
		indicates that no slave is selected
		"""
		self.table.resize(2, 2)
		self.set_node_name("No Slave")
		self.initialize_table()

	def initialize_table(self):
		if self.table is not None:
			self.vbox.remove(self.table)

		self.vbox.queue_draw()

		self.pos				= 2
		self.table = gtk.Table(	rows = 2, 
								columns = 2, 
								homogeneous = True)
		label = gtk.Label("Module Name: ")
		self.table.attach(		label,	#name of the child
								0,		#column left 
								1,		#column right 
								0, 		#row top
								1, 		#row bottom
								xoptions = gtk.EXPAND | gtk.FILL,
								yoptions = gtk.EXPAND | gtk.FILL,
								xpadding = self.txpad, #x padding
								ypadding = self.typad)	#y padding



		self.module_name_entry = gtk.Entry()
		self.module_name_entry.set_text("No Module")
		self.module_name_entry.show()
		self.table.attach(	self.module_name_entry,
								1,
								2,
								0,
								1,
								xoptions = gtk.EXPAND | gtk.FILL,
								yoptions = gtk.EXPAND | gtk.FILL,
								xpadding = self.txpad,
								ypadding = self.typad)


		label = gtk.Label("File Name: ")
		self.table.attach(		label,	#name of the child
								0,		#column left 
								1,		#column right 
								1, 		#row top
								2, 		#row bottom
								xoptions = gtk.EXPAND | gtk.FILL,
								yoptions = gtk.EXPAND | gtk.FILL,
								xpadding = self.txpad, #x padding
								ypadding = self.typad)	#y padding


	
		self.file_name_entry = gtk.Entry()
		self.file_name_entry.set_text("No Filename")
		self.file_name_entry.show()
		self.table.attach(	self.file_name_entry,
								1,
								2,
								1,
								2,
								xoptions = gtk.EXPAND | gtk.FILL,
								yoptions = gtk.EXPAND | gtk.FILL,
								xpadding = self.txpad,
								ypadding = self.typad)



		self.table.show()
		self.vbox.pack_start(	self.table,
								expand = False,
								fill = True,
								padding = self.txpad)

		self.vbox.show_all()



	def set_node_name(self, name):
		"""
		sets the name of the slave
		"""
		self.node_label.set_text(name)

	def set_module_name(self, module_name):
		"""
		sets the module name in the slave settings
		"""
		self.module_name_entry.set_text(module_name)
	
	def set_file_name(self, file_name):
		"""
		sets the file name in the property view
		"""
		self.file_name_entry.set_text(file_name)
	
	def set_property(self, name, value, editable):
		"""
		sets a name/value pair in the property_view
		and specifies if the name/value is editable
		"""
		#in the table add this value
		self.table.resize(self.pos + 1, 2)
		self.pos += 1
		label = gtk.Label(name)
		self.table.attach(	label,
							0,
							1,
							self.pos - 1,
							self.pos,
							xoptions = gtk.EXPAND | gtk.FILL,
							yoptions = gtk.EXPAND | gtk.FILL,
							xpadding = self.txpad,
							ypadding = self.typad)

		entry = gtk.Entry()
		entry.set_text(str(value))
		self.table.attach(	entry,
							1,
							2,
							self.pos - 1,
							self.pos,
							xoptions = gtk.EXPAND | gtk.FILL,
							yoptions = gtk.EXPAND | gtk.FILL,
							xpadding = self.txpad,
							ypadding = self.typad)





