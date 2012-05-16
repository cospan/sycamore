#main project properties view
import gtk
import status_text
import saputils


class ProjectPropertiesView:
	def __init__(self, sap_controller):
		builderfile = "project_properties_view.glade"
		builder = gtk.Builder()
		builder.add_from_file(builderfile)
		self.sc = sap_controller

		self.frame = builder.get_object("project_property_view")
		self.pt = builder.get_object("property_table")

		self.project_name = builder.get_object("entry_project_name")
		self.project_name.connect("focus-out-event", self.on_name_unfocus)
		#self.vendor_tool = builder.get_object("combobox_vendor_tool")	
		self.vendor_tool = gtk.combo_box_new_text()
		self.vendor_tool.show()
		self.vt_hid = None
		self.pt.attach (	self.vendor_tool,
							1,
							2,
							1,
							2,
							xoptions = gtk.EXPAND | gtk.FILL,
							yoptions = gtk.FILL,
							xpadding = 0,
							ypadding = 0)

#		self.bus = builder.get_object("combobox_bus_template")
		self.bus = gtk.combo_box_new_text()
		self.bus.show()
		self.bus_hid = None
		self.pt.attach (	self.bus,
							1,
							2,
							2,
							3,
							xoptions = gtk.EXPAND | gtk.FILL,
							yoptions = gtk.FILL,
							xpadding = 0,
							ypadding = 0)

		self.board = gtk.combo_box_new_text()
		self.board.show()
		self.board_hid = None
		self.pt.attach (	self.board,
							1,
							2,
							3,
							4,
							xoptions = gtk.EXPAND | gtk.FILL,
							yoptions = gtk.FILL,
							xpadding = 0,
							ypadding = 0)

		self.fpga_pn = builder.get_object("label_fpga_pn")
		self.constraint_files = builder.get_object("table_cfiles")
		self.constraint_list = []
		self.bind_tree = builder.get_object("main_bind_tree")

		self.project_name_change_cb = None
		self.vendor_tools_change_cb = None
		self.bus_change_cb = None
		self.board_change_cb = None
		self.constraint_change_cb = None


		#self.udpate = builder.get_object("button_update_properties")
		#self.update.connect("clicked", self.on_update_clicked
		#self.status = status_text.StatusText()


#	def on_update_clicked(self, widget):
#		"""
#		Update Button was pressed
#		"""

	def set_project_name_change_callback(self, func):
		self.project_name_change_cb = func

	def set_vendor_tool_change_callback(self, func):
		self.vendor_tools_change_cb = func

	def set_bus_change_callback(self, func):
		self.bus_change_cb = func

	def set_board_change_callback(self, func):
		self.board_change_cb = func
	
	def set_constraint_change_callback(self, func):
		self.constraint_change_cb = func

	def on_name_unfocus(self, widget, event):
		"""
		name unfocus event
		"""
		name = self.project_name.get_text()
		if name != self.sc.get_project_name():
			#print "user changed project name to %s" % name
			if self.project_name_change_cb is not None:
				self.project_name_change_cb(name)

	def on_vendor_tool_changed(self, combo):
		"""
		vendor tools have changed
		"""
		model = combo.get_model()
		it = combo.get_active_iter()
		name = model.get(it, 0)[0]
		print "vendor tool: " + name


		#print "user changed the vendor tool"
		if self.vendor_tools_change_cb is not None:
			self.vendor_tools_change_cb(name)


	def on_bus_changed(self, combo):
		"""
		bus template has changed
		"""
		model = combo.get_model()
		it = combo.get_active_iter()
		name = model.get(it, 0)[0]
		print "bus: " + name

		if self.bus_change_cb is not None:
			self.bus_change_cb(name)


	def on_board_changed(self, combo):
		"""
		different board selected
		"""
		model = combo.get_model()
		it = combo.get_active_iter()
		name = model.get(it, 0)[0]
		print "board name: " + name
		
		if self.board_change_cb is not None:
			self.board_change_cb(name)



	def on_constraint_file_clicked(self, check_box, name):
		"""
		when a user activates or de-activates a 
		constraint file
		"""
		enable = check_box.get_active()	
		print "%s set to %s" % (name, str(enable))
		if self.constraint_change_cb:
			self.constraint_change_cb(name, enable)

	

	def get_frame(self):
		return self.frame

	def setup(self):
		project_name = self.sc.get_project_name()
		self.project_name.set_text(project_name)	
		self.setup_vendor_tools_combo()
		self.setup_bus_combo()
		self.setup_board_combo()
		self.setup_fpga_part_number()
		self.setup_constraint_files()
		self.setup_bindings()

	def setup_vendor_tools_combo(self):
		if self.vt_hid is not None:
			self.vendor_tool.disconnect(self.vt_hid)
		model = gtk.ListStore(str, str)
		#model = self.vendor_tool.get_model()
		bt = self.vendor_tool
		model.clear()

		vendor = self.sc.get_vendor_tools()
		index = -1
		it = model.append()
		model.set(it, 0, "Xilinx")
		model.set(it, 1, "xilinx")
		if vendor == "xilinx":
			index = 0


#XXX: add additional tools like Altera here
#		it = model.append()
#		model.set(it, 0, "Altera")
#		model.set(it, 1, "altera")

		#compare this with the tools in the combo box
		#set the index of the build tool
		self.vendor_tool.set_model(model)
		self.vendor_tool.set_active(index)
		self.vt_hid = self.vendor_tool.connect("changed", self.on_vendor_tool_changed)

	def setup_bus_combo(self):
		if self.bus_hid is not None:
			self.bus.disconnect(self.bus_hid)
		model = gtk.ListStore(str, str)
		model.clear()

		bus = self.sc.get_bus_type()
		index = -1
		it = model.append()
		model.set(it, 0, "Wishbone")
		model.set(it, 1, "wishbone")
		if bus == "wishbone":
			index = 0


#XXX: add additional bus template here like Axie4
		#it = model.append()
		#model.set(it, 0, "Axie4")
		#model.set(it, 1, "axie4")
		#if bus_type == "axie4":
		#	index = 1

		#compare this with the template in the combobox
		#set the index of the bus template
		self.bus.set_model(model)
		self.bus.set_active(index)
		self.bus_hid = self.bus.connect("changed", self.on_bus_changed)


	def setup_board_combo(self):

		if self.board_hid is not None:
			self.board.disconnect(self.board_hid)
		model = gtk.ListStore(str)
		model.clear()
		boards = saputils.get_board_names()
		bn = self.sc.get_board_name()
		i = 0
		index = -1
		for board in boards:
			it = model.append()
			model.set(it, 0, board)
			if bn == board:
				index = i
			i += 1
		
		self.board.set_model(model)
		self.board.set_active(index)
		if self.board_hid is not None:
			self.board_hid = self.board.connect("changed", self.on_board_changed)


#XXX: Go through all the board configuration files to setup all the 
		#combo boxes associated with a board
		

	def setup_fpga_part_number(self):
		self.fpga_pn.set_text(self.sc.get_fpga_part_number())

	def setup_constraint_files(self):
		ct = self.constraint_files
		cl = self.constraint_list

		#remove all the previous entries
		if len(cl) > 0:

			for c in cl:
				ct.remove(c)
			
		#remove all the entries in the list
		cl = []

		cfiles = self.sc.get_constraint_file_names()
		#resize the table to fit all the new constraint files
		ct.resize(len(cfiles), 1)
		pcfiles = self.sc.get_project_constraint_files()


		index = 0
		for c in cfiles:
			cb = gtk.CheckButton(c)
			if c in pcfiles:
				cb.set_active(True)
			cb.show()
			ct.attach(	cb,
						0,
						1,
						index,
						index + 1,
						xoptions = gtk.EXPAND | gtk.FILL,
						yoptions = gtk.FILL,
						xpadding = 0,
						ypadding = 0)

			cb.connect("clicked", self.on_constraint_file_clicked, c)
			cl.append(cb)
			index += 1
						

		self.constraint_list = cl



	def setup_bindings(self):
		"""
		sets up all the bindings for the project
		"""
		model = gtk.ListStore(str, str, str)
		bt = self.bind_tree

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


		bd = self.sc.get_master_bind_dict()
		for port in bd.keys():
			pin = bd[port]["port"]
			direction = bd[port]["direction"]

			it = model.append()
			model.set(it, 0, port)
			model.set(it, 1, pin)
			model.set(it, 2, direction)

		bt.set_model(model)


