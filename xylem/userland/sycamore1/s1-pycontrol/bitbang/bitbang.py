import os
import sys
from array import array as Array
from pyftdi.ftdi import Ftdi



class BitBangController(object):
	

	PROGRAM_PIN 		=	0x20
	SOFT_RESET_PIN		=	0x40

	def __init__(self, idVendor, idProduct, interface):
		#all pins are in high impedance
		self.vendor = idVendor
		self.product = idProduct
		self.interface = interface

		self.f = Ftdi()
		self.f.open_bitbang(idVendor, idProduct, interface)


	def hiz(self):
		print "changing pins to high impedance"

	def is_in_bitbang(self):
		return self.f.bitbang_enabled

	def read_pins(self):
		return self.f.read_pins()

	def read_program_pin(self):
		return (self.PROGRAM_PIN & self.f.read_pins() > 0)
	
	def soft_reset_high(self):
		pins = self.f.read_pins()
		pins |= self.SOFT_RESET_PIN
		prog_cmd = Array('B', [0x01, pins])
		self.f.write_data(prog_cmd)
	
	def soft_reset_low(self):
		pins = self.f.read_pins()
		pins &= ~(self.SOFT_RESET_PIN)
		prog_cmd = Array('B', [0x00, pins])
		self.f.write_data(prog_cmd)

	def program_high(self):
		pins = self.f.read_pins()
		pins |= self.PROGRAM_PIN
		prog_cmd = Array('B', [0x01, pins])
		self.f.write_data(prog_cmd)

	def program_low(self):
		pins = self.f.read_pins()
		pins &= ~(self.PROGRAM_PIN)
		prog_cmd = Array('B', [0x00, pins])
		self.f.write_data(prog_cmd)
	
	def read_soft_reset_pin(self):
		return (self.SOFT_RESET_PIN & self.f.read_pins() > 0)

	def set_soft_reset_to_output(self):
		pin_dir = self.SOFT_RESET_PIN
		self.f.open_bitbang(self.vendor, self.product, self.interface, direction = pin_dir)
	
	def set_program_to_output(self):
		pin_dir = self.PROGRAM_PIN
		self.f.open_bitbang(self.vendor, self.product, self.interface, direction = pin_dir)
		
	def set_pins_to_input(self):
		self.f.open_bitbang(self.vendor, self.product, self.interface, direction = 0x00)


	def set_pins_to_output(self):
		self.f.open_bitbang(self.vendor, self.product, self.interface, direction = 0xFF)


	def pins_on(self):
		prog_cmd = Array('B', [0x01, 0xFF]) 
		self.f.write_data(prog_cmd)

	def pins_off(self):
		prog_cmd = Array('B', [0x01, 0x00]) 
		self.f.write_data(prog_cmd)






def main():
	print "main"

if __name__ == "__main__":
	print "starting"
	main()
