#include <asm-generic/ioctl.h>

#define BRIDGE_IOC_NUM 'S'
#define BRIDGE_IOC_MAX_NUM 11
#define BRIDGE_IOC_CURRESGET    _IO(BRIDGE_IOC_NUM, 1)            // read current resource - (0 = none)
#define BRIDGE_IOC_CURRESSET    _IO(BRIDGE_IOC_NUM, 2)            // set current resource
#define BRIDGE_IOC_CURBASE      _IOR_BAD(BRIDGE_IOC_NUM, 3, base)     // read current resource base address
#define BRIDGE_IOC_CURBASEMAP   _IOR_BAD(BRIDGE_IOC_NUM, 4, base)     // read current resource remaped base address ( 0 - not remaped)
#define BRIDGE_IOC_CURBASESIZE  _IOR_BAD(BRIDGE_IOC_NUM, 5, base_size)// read current resource size
#define BRIDGE_IOC_NUMOFRES     _IO(BRIDGE_IOC_NUM, 6)            // read number of found resources

#define BRIDGE_P_IMG_CTRL1_ADDR	0x110
#define BRIDGE_P_BA1_ADDR		0x114
#define BRIDGE_P_AM1_ADDR		0x118
#define BRIDGE_P_TA1_ADDR		0x11c

#define BRIDGE_W_IMG_CTRL1_ADDR        0x184
#define BRIDGE_W_BA1_ADDR              0x188
#define BRIDGE_W_AM1_ADDR              0x18C
#define BRIDGE_W_TA1_ADDR              0x190
