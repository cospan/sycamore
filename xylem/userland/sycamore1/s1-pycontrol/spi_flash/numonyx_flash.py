import serialflash
from serialflash import SerialFlash

class Numonyx_Flash_device(SerialFlash):

	
    CMD_WRITE_ENABLE	=	0x06 # Write enable
    CMD_WRITE_DISABLE	=	0x04 # Write disable
	CMD_READ_JEDEC		=	0x9F # Read JEDED ID # (20H)
    CMD_READ_STATUS		=	0x05 # Read status register
    CMD_WRSR			=	0x01 # Write status register
    CMD_READ_LO_SPEED	=	0x03 # Read @ low speed
    CMD_READ_HI_SPEED	=	0x0B # Read @ high speed
    CMD_PROGRAM_PAGE	=	0x02 # Write page
    CMD_ERASE_BLOCK		=	0xD8 # Erase full block
    CMD_PROGRAM_PAGE	=	0x02
    CMD_ERASE_SECTOR	=	0xD8
    CMD_ERASE_CHIP		=	0xC7

    #CMD_EWSR = 0x50 # Enable write status register
    #CMD_ERASE_SUBSECTOR = 0x20
    #CMD_ERASE_HSECTOR = 0x52


	PAGE_DIV			=	
	SUBSECTOR_DIV		=
	HSECTOR_DIV			=
	SECTOR_DIV			=
	PAGE_SIZE			=
	SUBSECTOR_SIZE		=
	HSECTOR_SIZE		=
	SECTOR_SIZE			=
	SPI_FREQUENCY_MAX	=	75 # MHz
	ADDRESS_WIDTH		=	1


	SR_WIP				=
	SR_WEL				=
	SR_BP0				=
	SR_BP1				=
	SR_PB2				=

	def __init__(self, spiport):
		self.__spi = spiport;

	def get_capacity(self):
		return len(self)


def main():
	print "hi"


if __name__ == "__main__":
	main()
