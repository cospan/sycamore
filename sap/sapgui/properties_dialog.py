import gtk
import sap_controller
import status_text
import getpass

class PropertiesDialog:
	def __init__(self):
		builderfile = "properties_dialog.glade"
		builder = gtk.Builder()
		builder.add_from_file(builderfile)
		self.status = status_text.StatusText()

		self.prop_dialog = builder.get_object("properties_dialog")
		self.compress_check = builder.get_object("compress_checkbox")
		self.auto_detect = builder.get_object("auto_detect_button")
		self.vendor_loc = builder.get_object("vendor_tool_loc_entry")
		self.remote_check = builder.get_object("remote_checkbox")

		self.remote_name = builder.get_object("remote_host_entry")
		self.port = builder.get_object("port_entry")
		self.username = builder.get_object("username_entry")
		self.username.set_text(getpass.getuser())

		self.password = builder.get_object("password_entry")

		self.cancel_button = builder.get_object("cancel_button")
		self.accept_button = builder.get_object("accept_button")


		self.test_conn_button = builder.get_object("test_conn_button")
		self.test_conn_status = builder.get_object("test_conn_entry")

		self.auto_detect.connect("clicked", self.on_auto_detect)
		self.cancel_button.connect("clicked", self.on_cancel)
		self.accept_button.connect("clicked", self.on_accept)
		self.remote_check.connect("toggled", self.remote_check_change)
		self.compress_check.connect("toggled", self.compress_check_change)
		self.test_conn_button.connect("clicked", self.on_test_conn)

		self.remote = False
		self.compress = False

	def show(self):
		self.prop_dialog.show()

	def on_auto_detect(self, widget):
		#attempt to auto detect the tool
		print "auto detect"

	def on_cancel(self, widget):
		self.prop_dialog.hide()
		print "cancel"

	def on_accept(self, widget):
		self.prop_dialog.hide()
		#save all variables
		print "accept"

	def remote_check_change(self, widget):
		print "remote check change"
		if self.remote_check.get_active():
			print "remote active"
			self.remote = True
		else:
			print "remote not active"
			self.remote = False

	def is_remote(self):
		return self.remote

	def compress_check_change(self, widget):
		if self.compress_check.get_active():
			print "compress"
			self.compress = True
		else:
			print "dont compress"
			self.compress = False
	
	def is_compressed(self):
		return self.compress

	def on_test_conn(self, widget):
		print "testing connection..."
