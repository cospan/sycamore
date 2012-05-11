#main project properties view
import gtk
import status_text


class ProjectPropertiesView:
	def __init__(self, sap_controller):
		builderfile = "project_properties_view.glade"
		builder = gtk.Builder()
		builder.add_from_file(builderfile)
		self.sc = sap_controller

		self.frame = builder.get_object("project_property_view")

		self.project_name = builder.get_object("entry_project_name")
		self.build_tool = builder.get_object("combobox_build_tool")	
		self.bus_template = builder.get_object("combobox_bus_template")
		self.board_name = builder.get_object("combobox_bus_template")
		self.fpga_pn = builder.get_object("label_board_name")
		self.config_files = builder.get_object("treeview_configuration_files")
		self.bind_tree = builder.get_object("main_bind_tree")

		self.status = status_text.StatusText()


	def setup(self):
		project_name = self.sc.get_project_name()
		self.project_name.set_text(project_name)	
		self.setup_vendor_tools_combo()
		self.setup_bus_combo()
		self.setup_board_combo()

	def setup_vendor_tools_combo(self):
		model = self.build_tool.get_model()
		model.clear()

		it = model.append()
		model.set(it, 0, "Xilinx")

#XXX: add additional tools like Altera here
#		it = model.append()
#		model.set(it, 0, "Altera")

		#get the build tool from the configuration file
		bt = self.sc.get_vendor_tools()

		#compare this with the tools in the combo box
		#set the index of the build tool

	def setup_bus_combo(self):
		model = self.bus_template.get_model()
		model.clear()

		it = model.append()
		model.set(it, 0, "Wishbone")

#XXX: add additional bus template here like Axie4
		#it = model.append()
		#model.set(it, 0, "Axie4")

		template = self.sc.get_bus_type()
		#compare this with the template in the combobox
		#set the index of the bus template


	def setup_board_combo(self):
		model = self.board_name.get_model()
		model.clear()

#XXX: Go through all the board configuration files to setup all the 
		#combo boxes associated with a board
		


		
