#! /usr/bin/python

"""
Sycamore: the main front interface to the Sycamore bus system on the FPGA	
"""

"""
Changes:
11/12/2011
	-Changed read_data and read_mem_data to return a list of double words
	read from sycamore
11/07/2011
	-Added the capability to detect interrupts and read find out if a slave was the one that
		generated the interrupt
	-Perhaps launching a second read thread so the code always detects interrupts

10/30/2011
	-Changed the number of devices read from DRT, now the actual DRT slave is not counted
	-Made the script executable
	-Changed the unit test to actually call functions read and write as apposed to generating
		the serial read/write manually
	-Added unit test for memory devices
"""

import serial
import string
import time


class Sycamore:

	drt_string = ""
	drt_lines = []
	interrupts = 0
	interrupt_address = 0
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

	def read_mem_data (self, dev_index, offset, data_count = 0):
		response = []
		address = self.get_address_from_dev_index(dev_index)
		#data_count = 0 will read one double word, so if data_count says 1 just do a default read
		if (data_count > 0):
			data_count = data_count - 1;

		read_cmd = "L%0.7X00010002%0.8X00000000"
		read_cmd = (read_cmd) % (data_count, address + offset)
		self.ser.write(read_cmd)
		read_resp = self.ser.read(25 + (data_count * 8))
		print "read command: " + read_cmd
		print "response: " + read_resp

		if (len(read_resp) > 0):
			for i in range (0, data_count + 1):
				response.append(string.atoi(read_resp[(17 + (i * 8)):(25 + (i * 8))], 16))
		return response
		
	def read_data(self, dev_index, offset, data_count = 0):
		response = []
		address = self.get_address_from_dev_index(dev_index)
		#data_count = 0 will read one double word, so if data_count says 1 just do a default read
		if (data_count > 0):
			data_count = data_count - 1;

		read_cmd = "L%0.7X00000002%0.8X00000000"
		read_cmd = (read_cmd) % (data_count, address + offset)
		self.ser.write(read_cmd)
		read_resp = self.ser.read(25 + (data_count * 8))
		print "read command: " + read_cmd
		print "response: " + read_resp

		if (len(read_resp) > 0):
			for i in range (0, data_count + 1):
				response.append(string.atoi(read_resp[(17 + (i * 8)):(25 + (i * 8))], 16))

		return response
		
	def write_mem_data(self, dev_index, offset, data):

		if (not isinstance (data, list)):
			data = [data]

		address = self.get_address_from_dev_index(dev_index)
		data_count = len(data) - 1
		write_cmd = "L%0.7X00010001%0.8X"
		write_cmd = (write_cmd) % (data_count, address + offset)

		for i in range (0, data_count + 1):
			data_string = ("%0.8X") % data[i]
			write_cmd += data_string;

		print "out string: " + write_cmd
		self.ser.flushInput()
		self.ser.write(write_cmd)
		write_resp = self.ser.read(25)
		if (len(write_resp) == 0):
			return False
		return True

	def write_data(self, dev_index, offset, data):

		if (not isinstance (data, list)):
			data = [data]

		address = self.get_address_from_dev_index(dev_index)
		data_count = len(data) - 1
		write_cmd = "L%0.7X00000001%0.8X"
		write_cmd = (write_cmd) % (data_count, address + offset)

		for i in range (0, data_count + 1):
			data_string = ("%0.8X") % data[i]
			write_cmd += data_string;

		print "out string: " + write_cmd
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
			#print "temp string: " + temp_string
			if (len(temp_string) == 0):
				return False
			else:
				self.drt_string = self.drt_string + temp_string.__getslice__(17, 25) + "\n"
		
			if (index == 1):
				size_string = temp_string.__getslice__(17, 25)
				#print "size_string: " + size_string
				#print "number of device: " + str(string.atoi(size_string, 16))
				self.num_of_devices = string.atoi(size_string, 10)
			index = index + 1
			count = count - 1

		#print "number of devices: " + str(self.num_of_devices)
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

	def wait_for_interrupts(self, wait_time = 1):
		temp_timeout = self.ser.timeout
		self.ser.timeout = wait_time
		temp_string = self.ser.read(25)
		#put the old timeout back
		self.ser.timeout = temp_timeout
		if(len(temp_string) == 0):
			return False
		print "interrupt string: " + temp_string
		self.interrupt_address = string.atoi(temp_string[9:16], 16)
		self.interrupts = string.atoi(temp_string[17:25], 16)
		return True

	def is_interrupt_for_slave(self, device_id = 0):
		device_id += 1
		if (2**device_id & self.interrupts):
			return True
		return False

	def slave_unit_test(self):
		print "Found " + str(self.num_of_devices) + " slave(s)"
		print "Searching for standard devices..."
		for dev_index in range (0, (self.num_of_devices)):
			device_id = string.atoi(self.drt_lines[((dev_index + 1) * 4)], 16)
			flags = string.atoi(self.drt_lines[((dev_index + 1) * 4) + 1], 16)
			address_offset = string.atoi(self.drt_lines[((dev_index + 1) * 4) + 2], 16)
			num_of_registers = string.atoi(self.drt_lines[((dev_index + 1) * 4) + 3], 16)
			print "device ID: " + str(device_id)
			data_list = list()
			if (device_id == 1):
				print "found gpio"
				print "enable all GPIO's"
				self.write_data(dev_index, 1, 0xFFFFFFFF)
				print "flash all LED's once"
				#clear
				self.write_data(dev_index, 0, 0x00000000)
				self.write_data(dev_index, 0, 0xFFFFFFFF)
				time.sleep(1)
				self.write_data(dev_index, 0, 0x00000000)
				time.sleep(.1)
	
				print "read buttons in 1 second..."
				time.sleep(1)
				gpio_read = self.read_data(dev_index, 0)
				print "gpio read: " + hex(gpio_read[0])

				print "testing interrupts, setting interrupts up for postivie edge detect"
				#positive edge detect
				self.write_data(dev_index, 4, 0xFFFFFFFF)
				#enable all interrupts
				self.write_data(dev_index, 3, 0xFFFFFFFF)

#				print "testing burst write: "
#				self.write_data(dev_index, 0, [1, 2, 3, 4, 5])

				
#				print "testing burst read, results should be 1, 2: "
#				gpio_read = self.read_data(dev_index, 0, 5)
#				for v in gpio_read:
#					print "gpio: " + str(v)

				print "testing interrupts, waiting for 5 seconds..."
				
				if (self.wait_for_interrupts(wait_time = 5)):
					#print "detected interrupts!"
					#print "interrupts: " + str(self.interrupts)
					#print "device index: " + str(dev_index)
					#print "blah: " + str(2**(dev_index + 1))
					if (self.is_interrupt_for_slave(dev_index)):
						print "interrupt for GPIO!"
						gpio_read = self.read_data(dev_index, 0)
						print "gpio read: " + hex(gpio_read[0])


	

			elif (device_id == 10):
				print "found LCD"
				print "enable"
				self.write_data(dev_index, 0, 0x00000001)
				print "set all black for two seconds"
				self.write_data(dev_index, 1, 0x00000000)
				time.sleep(2)
				print "set all red for two seconds"
				self.write_data(dev_index, 1, 0x00FF0000)
				time.sleep(2)
				print "set all green for two seconds"
				self.write_data(dev_index, 1, 0x0000FF00)
				time.sleep(2)
				print "set all blue for two seconsd"
				self.write_data(dev_index, 1, 0x000000FF)
				time.sleep(2)
				print "lcd disable"
				self.write_data(dev_index, 0, 0x00000000)


			elif (device_id == 5):
				print "found Memory device"
				mem_bus = False
				if ((flags & 0x00010000) > 0):
					print "Memory slave is on Memory bus"
					mem_bus = True 
				else:
					print "Memory slave is on peripheral bus"

				print "Burst Write to 10 locations:"
				if (mem_bus):
					self.write_mem_data(dev_index, 0, [0,1,2,3,4,5,6,7,8,9])
				else:
					self.write_data(dev_index, 0, [0,1,2,3,4,5,6,7,8,9])
#				for i in range (0, 10):
#					print "writing " + str(i) + " to " + str(i * 4)
#					if (mem_bus):
#						self.write_mem_data(dev_index, i * 4, i)
#					else:
#						self.write_data(dev_index, i * 4, i)

				print "Burst Read from the 10 locations:"
				mem_value = []
				if (mem_bus):
					mem_value = self.read_mem_data(dev_index, 0, 10)
				else:
					mem_value = self.read_data(dev_index, 0, 10)
				for i in range (0, len(mem_value)):
					print "reading " + str(mem_value[i]) + " from " + str(i * 4)
#				for i in range (0, 10):
#					if (mem_bus):
#						mem_value = self.read_mem_data(dev_index, i * 4)
#					else:
#						mem_value = self.read_mem_data(dev_index, i * 4)
#
#					print "reading " + str(mem_value[0]) + " from " + str(i * 4)


	
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
	if (not ping_result):
		print "ping fail :("

	syc.drt_string
	if (len(syc.drt_string) == 0):
		print "nothing read from DRT"
	else:
		print "drt table: \n" + syc.drt_string
		syc.slave_unit_test()

	

	




