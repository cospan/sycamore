import serial
import string
import time
import sycamore

def turn_on(syc, lcd_index):
	syc.write_data(lcd_index, 0, 1)	

def turn_off(syc, lcd_index):
	syc.write_data(lcd_index, 0, 0)

def set_color(syc, lcd_index, red, blue, green):
	color = red << 16 | blue << 8 | green
	syc.write_data(lcd_index, 1, color) 

def is_on(syc, lcd_index):
	lcd_flags = syc.read_data(lcd_index, 0)
	if (lcd_flags == -1):
		print "Error read timed out"
		return False
	if ((lcd_flags & 1) > 0):
		return True
	return False

if __name__== "__main__":
	syc = sycamore.Sycamore()
	lcd_index = syc.get_device_index(10)
	print "drt:\n"
	print syc.drt_string
	print "index = " + str(lcd_index)
	if (lcd_index != -1):
		print "address = " + hex(syc.get_address_from_dev_index(lcd_index))
		set_color(syc, lcd_index, 0, 255, 0)
		turn_on(syc, lcd_index)
		if (is_on(syc, lcd_index)):
			print "lcd is on"
		else:
			print "lcd is off"
	else:
		print "index out of range"

#	time.sleep(2)
#	if (is_on(syc, lcd_index)):
#		print "lcd is on"
#	else:
#		print "lcd is off"
#	set_color(syc, lcd_index, 0, 0, 255)
#	time.sleep(2)
#	if (is_on(syc, lcd_index)):
#		print "lcd is on"
#	else:
#		print "lcd is off"
#	set_color(syc, lcd_index, 255, 0, 0)
#	time.sleep(2)
#	turn_off(syc, lcd_index)
#	if (not is_on(syc, lcd_index)):
#		print "lcd is off"


