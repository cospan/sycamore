import serial
import string
import time
import sycamore

def write_mem(syc, mem_index, mem_address, data):
	syc.write_data(mem_index, mem_address, data)

def read_mem(syc, mem_index, mem_address, data):
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
	if (mem_index != -1):
		print "mem address = " + hex(syc.get_address_from_dev_index(mem_index))
		for addr in range (0, (mem_size / 4)):
			mem_data = read_mem(syc, mem_index, addr * 4)
			print ".",	
			if (mem_data != addr):
				print "first read failed at address: " + str(addr * 4)+ " data: " + str(mem_data) + " != " + str(addr * 4) 
				break

		print "populating memory"
		for addr in range (0, mem_size * 4):
			write_mem(syc, mem_index, addr * 4, addr * 4)
			print ".",	
		
		print " "
		print "reading memory"
		for addr in range (0, mem_size * 4):
			mem_data = read_mem(syc, mem_index, addr * 4)
			print ".",	
			if (mem_data != addr):
				print "first read failed at address: " + str(addr * 4)+ " data: " + str(mem_data) + " != " + str(addr * 4) 
				mem_test	= False
				break

	if (mem_test == True):
		print "Test passed!"
	else:
		print "Test Failed!"

