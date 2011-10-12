import serial
import string
import time
import sycamore

def write_mem(syc, mem_index, mem_address, data):
	syc.write_data(mem_index, mem_address, data)

def read_mem(syc, mem_index, mem_address):
	mem_data = syc.read_data(mem_index, mem_address)
	return mem_data

if __name__=="__main__":
	syc = sycamore.Sycamore()
	mem_index = syc.get_device_index(5)
	
	mem_size = 2**23
	mem_test = True

	print "drt:\n"
	print syc.drt_string
	print "index = " + str(mem_index)
	print "memory size: ", hex(mem_size) 
	ddr_address = syc.get_address_from_dev_index(mem_index)
	print "ddr_slave offset " + hex(ddr_address)

	if (mem_index != -1):
		data_out = 0x00001EAF
#		data_out = 0
#		data_out = 1
		mem_address	=	0
		en_write = 0
		en_write = 1
		if (en_write):
			print "writing " + hex(data_out) + " to address " + hex(mem_address)
			write_mem(syc, mem_index, mem_address, data_out)

		print "reading from memory location " + hex(mem_address) 
		mem_data = read_mem(syc, mem_index, mem_address)
		if (mem_data == -1):
			mem_test = False
		else:
			print "data at address " + hex(mem_address) + ":" + hex(mem_data)

		print "mem address = " + hex(syc.get_address_from_dev_index(mem_index))
		for addr in range (0, (mem_size / 4)):
			mem_data = read_mem(syc, mem_index, addr * 4)
			print "data: " + hex(mem_data) + " at: " + hex(addr)

			if (mem_data != (addr * 4)):
				print "Fail Initial read!" 
				break
		print "populating first 10 memory locations"
		for addr in range (0, 10):
			write_mem(syc, mem_index, addr * 4, addr)
			print "address: " + str(addr)	
		
		print " "
		print "reading first 10 memory locations"
		for addr in range (0, 10):
			mem_data = read_mem(syc, mem_index, addr * 4)
			print "data: " + hex(mem_data) + " at: " + hex(addr)
			if (mem_data != addr):
				print "Fail Initial read!" 
				mem_test	= False
				break
	else:
		mem_test = False
	if (mem_test == True):
		print "Test passed!"
	else:
		print "Test Failed!"

