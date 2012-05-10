#status text box singleton
import gtk

#status view item always the same
_buffer = None

class StatusText:
	def __init__(self, status_view = None):
		print "entered status text init"
#		if _sv is not None:
#			return
		if status_view is None:
			return

		if type(status_view) is not gtk.TextView:
			print "not type text view"
			return

		global _buffer
		_buffer = status_view.get_buffer()
		global _level
		_level = 5

#		print "initial level %d" % (_level)
		# 5 == print everything
		# 0 == print nothing

	def set_print_level(self, level):
		if level > 5:
			level = 5
		if level < 0:
			level = 0

		_level = level
		print "setting level to %d" % (_level)
		self.append_text("setting level to %d\n" % (_level))

	def get_print_level(self):
		return _level

	def append_text(self, text):
		st = _buffer.get_start_iter()
		en = _buffer.get_end_iter()
		_buffer.set_text(_buffer.get_text(st, en) + text)


	def print_error(self, f, text):
		if _level < 1:
			return

		f = f.rpartition("/")[2]
		if _buffer is None:
			print "_sv is not instantiated yet"
			return
		buf = "Error (%s): %s\n" % (f, text)
		self.append_text(buf)

	def print_warning(self, f, text):
		if _level < 2:
			return

		f = f.rpartition("/")[2]
		if _buffer is None:
			print "_buffer is not instantiated yet"
			return
		buf = "Warning (%s): %s\n" % (f, text)
		self.append_text(buf)

	def print_info(self, f, text):
		if _level < 3:
			return

		f = f.rpartition("/")[2]
		if _buffer is None:
			print "_buffer is not instantiated yet"
			return

		buf = "Info (%s): %s\n" % (f, text)
		self.append_text(buf)
 
	def print_debug(self, f, text):
		if _level < 4:
			return

		f = f.rpartition("/")[2]
		if _buffer is None:
			print "_buffer is not instantiated yet"
			return

 		buf = "Debug (%s): %s\n" % (f, text)
		self.append_text(buf)

	def print_verbose(self, f, text):
#		print "level: " + str(_level)
		if _level < 5:
			return
		
		f = f.rpartition("/")[2]
		if _buffer is None:
			print "_buffer is not instantiated yet"
			return

		buf = "Verbose (%s): %s\n" % (f, text)
		self.append_text(buf)

