#generate_script


def read_wb_slave_template_file(filename=""):
	template_file_string = ""
	try:
		#open the template file at the default location and read location
	except:
		print "Couldn't find template file"
	return template_file_string

if __name__=="__main__":
	#check if the slave name exists
	#Read in the template file as a string
	#replace the name of module with the user defined template
	#generate a folder structure in the rtl/wishbone/slave/<slave_name>
	#create the new wishbone_slave
	#generate a folder in the sim/wishbone/slave/<slave_name>
	#copy all the sim/wishbone/slave_template files to the new directory
	#modify the file_list.txt contents to compile the new slave
	#modify the wishbone_master_tb.v to include the RTL slave
