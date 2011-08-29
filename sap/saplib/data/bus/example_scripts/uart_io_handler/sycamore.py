import serial
import string
import time


class Sycamore:

	drt_string = ""
	drt_lines = []
	num_of_devices = 0
	ser = serial.Serial()

	def __init__(self, device_name='/dev/ttyUSB0', baudrate = 9600):
		self.open_serial(device_name, baudrate)
#		print "opened serial port: "
#		print self.ser.port
#		print str(self.ser.baudrate) + "\n"
		if (self.ping()):
			if (self.read_drt()):
				self.drt_lines = self.drt_string.splitlines()
			else:
				print "Failed to read DRT"
		else:
			print "No ping response"

	def __del__(self):
		if (isinstance(self.ser, serial.Serial)):
			self.ser.close()

	def ping(self):
		self.ser.write("L0000000000000000000000000000000")
		ping_string = self.ser.read(25)
#		print "read: " + ping_string
		if (len(ping_string) > 0):
			return True
		return False

	def get_address_from_dev_index(self, dev_index):	
		return string.atoi(self.drt_lines[((dev_index + 1) * 4) + 2], 16)

	def read_data(self, dev_index, offset):
		address = self.get_address_from_dev_index(dev_index)
		read_cmd = "L000000000000002%0.8X00000000"
		read_cmd = (read_cmd) % (address + offset)
		self.ser.write(read_cmd)
		read_resp = self.ser.read(25)
		if (len(read_resp) == 0):
			return -1
		return string.atoi(read_resp.__getslice__(17, 25))
		
	
	def write_data(self, dev_index, offset, data):
		data_string = ("%0.8X") % data
		address = self.get_address_from_dev_index(dev_index)
		write_cmd = "L000000000000001%0.8X" + data_string
		write_cmd = (write_cmd) % (address + offset)
#		print "out string: " + write_cmd
		self.ser.flushInput()
		self.ser.write(write_cmd)
		write_resp = self.ser.read(25)
		if (len(write_resp) == 0):
			return False
		return True

	def read_drt(self):
		self.drt_string = ""
		count = 4
		index = 0	
		self.num_of_devices = 0
		while (count > 0):

			#clear things out
			self.ser.write("00000")
			cmd_string = "L000000000000002%0.8X00000000"
			cmd_string = (cmd_string) % index
			#print "cmd_string: " + cmd_string
			#return
			self.ser.write(cmd_string)
			temp_string = self.ser.read(25)
			if (len(temp_string) == 0):
				return False
			else:
				self.drt_string = self.drt_string + temp_string.__getslice__(17, 25) + "\n"
		
			if (index == 1):
				size_string = temp_string.__getslice__(9,17)
				#print "size_string: " + size_string
				#print "number of device: " + str(string.atoi(size_string, 16))
				self.num_of_devices = string.atoi(size_string, 10)
			index = index + 1
			count = count - 1

		#print "number of devices: " + str(num_of_devices)
		#print "id block: \n" + drt_string
		count = 0
		while (count < ((self.num_of_devices) * 4)):
			self.ser.write("0000")
			cmd_string = "L000000000000002%0.8X00000000"
			cmd_string = (cmd_string) % (count + 4)
			#print "cmd_string: " + cmd_string
			#return
			self.ser.write(cmd_string)
			temp_string = self.ser.read(25)
			if (len(temp_string) == 0):
				return False
			else:
				self.drt_string = self.drt_string + temp_string.__getslice__(17, 25) + "\n"
			count = count + 1
		#got through it all
		return True
		
	def is_device_attached(self, device_id = 0):
		for dev_index in range (0, self.num_of_devices):
			dev_id = string.atoi(self.drt_lines[((dev_index + 1) * 4)], 16)
			if (dev_id == device_id):
				return True
		return False
	
	def get_device_index(self, device_id):
		for dev_index in range(0, self.num_of_devices):
			dev_id = string.atoi(self.drt_lines[((dev_index + 1) * 4)], 16)
			address_offset = string.atoi(self.drt_lines[((dev_index + 1) * 4) + 2], 16)
			if (device_id == device_id):
				return dev_index
		return -1
		

	def slave_unit_test(self):
		print "Found " + str(self.num_of_devices) + " slave(s)"
		print "Searching for standard devices..."
		for dev_index in range (0, self.num_of_devices):
			device_id = string.atoi(self.drt_lines[((dev_index + 1) * 4)], 16)
			flags = string.atoi(self.drt_lines[((dev_index + 1) * 4) + 1], 16)
			address_offset = string.atoi(self.drt_lines[((dev_index + 1) * 4) + 2], 16)
			num_of_registers = string.atoi(self.drt_lines[((dev_index + 1) * 4) + 3], 16)
			print "device ID: " + str(device_id)
			if (device_id == 1):
				print "found gpio"
				print "enable all GPIO's"
				cmd_string = ("L000000000000001%0.8XFFFFFFFF") % (address_offset + 1)
				print "cmd string: " + cmd_string
				self.ser.write(cmd_string)
				self.ser.read(25)
				print "flash all LED's once"
				#clear
				leds_off = ("L000000000000001%0.8X00000000") % (address_offset)
				print "leds off string " + leds_off
				self.ser.write(leds_off)
				self.ser.read(25)
				time.sleep(0.1)
				leds_on = ("L000000000000001%0.8XFFFFFFFF") % (address_offset)
				print "leds on string " + leds_on
				self.ser.write(leds_on)
				self.ser.read(25)
				time.sleep(1)
				leds_off = ("L000000000000001%0.8X00000000") % (address_offset)
				self.ser.write(leds_off)
				self.ser.read(25)
				time.sleep(0.1)
	
				print "read buttons in 1 second..."
				gpio_read = ("L000000000000002%0.8X00000000") % (address_offset)
				print "gpio read string: " + gpio_read
				self.ser.write(gpio_read)
				old_timeout = self.ser.timeout
				self.ser.timeout = 1
				gpio_val_string = self.ser.read(25)
				print "gpio string: " + gpio_val_string
				self.ser.timeout = old_timeout
				if (len(gpio_val_string) > 0):
					gpio_val = string.atoi(gpio_val_string.__getslice__(17, 25), 16)
					print "gpio values: " + str(gpio_val)
	

			elif (device_id == 10):
				print "found LCD"
				lcd_en = ("L000000000000001%0.8X00000001") % (address_offset)
				print "enable"
				self.ser.write(lcd_en)
				self.ser.read(25)
				print "set all black for two seconds"
				black_string = ("L000000000000001%0.8X00000000") % (address_offset + 1)
				self.ser.write(black_string)
				self.ser.read(25)
				time.sleep(2)
				print "set all red for two seconds"
				red_string = ("L000000000000001%0.8X00FF0000") % (address_offset + 1)
				self.ser.write(red_string)
				self.ser.read(25)
				time.sleep(2)
				print "set all green for two seconds"
				green_string = ("L000000000000001%0.8X0000FF00") % (address_offset + 1)
				self.ser.write(green_string)
				self.ser.read(25)
				time.sleep(2)
				print "set all blue for two secons"
				blue_string = ("L000000000000001%0.8X000000FF") % (address_offset + 1)
				self.ser.write(blue_string)
				self.ser.read(25)
				time.sleep(2)
				print "lcd disable"
				lcd_disable = ("L000000000000001%0.8X00000000") % (address_offset)
	
	def open_serial(self, dev_name='/dev/ttyUSB0', baudrate=9600):
		self.ser = serial.Serial(dev_name, baudrate)
#		self.ser.port = dev_name
#		self.ser.baudrate = baudrate
#		self.ser.open()
		self.ser.timeout = 1
		self.ser.flushInput()
		if (self.ser == None):
			print ("Error openeing serial port :(")
	
if __name__ == '__main__':
	print "starting..."
	syc = Sycamore()
	ping_result = syc.ping()
	#ping 
	if (ping_result):
		print "ping fail :("

	syc.drt_string
	if (len(syc.drt_string) == 0):
		print "nothing read from DRT"
	else:
		print "drt table: \n" + syc.drt_string
		syc.slave_unit_test()

	

	




