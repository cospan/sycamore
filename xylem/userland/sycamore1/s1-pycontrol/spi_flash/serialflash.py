# Copyright (c) 2010-2011, Emmanuel Blot <emmanuel.blot@free.fr>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the Neotion nor the names of its contributors may
#       be used to endorse or promote products derived from this software
#       without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL NEOTION BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
# LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
# EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

import os
import sys
import time
from inspect import isclass
import inspect
from pyftdi.ftdi import Ftdi
from pyftdi.spi import SpiController
from pyftdi.misc import hexdump
from array import array as Array


class SerialFlashNotSupported(Exception):
    """Exception thrown when a non-existing feature is invoked"""

class SerialFlashUnknownJedec(SerialFlashNotSupported):
    """Exception thrown when a JEDEC identifier is not recognized"""
    def __init__(self, jedec):
        from binascii import hexlify
        SerialFlashNotSupported.__init__(self, "Unknown flash device: %s" % \
                                         hexlify(jedec))

class SerialFlashTimeout(Exception):
    """Exception thrown when a flash command cannot be completed in a timely
       manner"""

class SerialFlashValueError(ValueError):
    """Exception thrown when a parameter is out of range"""


class SerialFlash(object):
    """Interface of a generic SPI flash device"""

    FEAT_NONE = 0x000         # No special feature
    FEAT_LOCK = 0x001         # Basic, revertable locking
    FEAT_INVLOCK = 0x002      # Inverted (bottom/top) locking
    FEAT_SECTLOCK = 0x004     # Arbitrary sector locking
    FEAT_OTPLOCK = 0x008      # OTP locking available
    FEAT_UNIQUEID = 0x010     # Unique ID
    FEAT_SECTERASE = 0x100    # Can erase whole sectors
    FEAT_HSECTERASE = 0x200   # Can erase half sectors
    FEAT_SUBSECTERASE = 0x400 # Can erase sub sectors

    def read(self, address, length):
        """Read a sequence of bytes from the specified address."""
        raise NotImplementedError()

    def write(self, address, data):
        """Write a sequence of bytes, starting at the specified address."""
        raise NotImplementedError()

    def erase(self, address, length):
        """Erase a block of bytes. Address and length depends upon device-
           specific constraints."""
        raise NotImplementedError()

    def can_erase(self, address, length):
        """Tells whether a defined area can be erased on the Spansion flash
           device. It does not take into account any locking scheme."""
        raise NotImplementedError()

    def is_busy(self):
        """Reports whether the flash may receive commands or is actually
           being performing internal work"""
        raise NotImplementedError()

    def get_capacity(self):
        """Get the flash device capacity in bytes"""
        raise NotImplementedError()

    def get_capabilities(self):
        """Flash device capabilities."""
        return SerialFlash.FEAT_NONE

    def get_locks(self):
        """Report the currently write-protected areas of the device."""
        raise NotImplementedError()

    def set_lock(self, address, length, otp=False):
        """Create a write-protected area. Device should have been unlocked
           first."""
        raise NotImplementedError()

    def unlock(self):
        """Make the whole device read/write"""
        pass

    def get_unique_id(self):
        """Return the unique ID of the flash, if it exists"""
        raise NotImplementedError()


class SerialFlashManager(object):
    """Serial flash manager.

       Automatically detects and instanciate the proper flash device class
       based on the JEDEC identifier which is read out from the device itself.
    """

    CMD_JEDEC_ID = 0x9F

    def __init__(self, vendor, product, interface=1):
        self._ctrl = SpiController(silent_clock=False)
        self._ctrl.configure(vendor, product, interface)

    def get_flash_device(self, cs=0):
        """Obtain an instance of the detected flash device"""
        spi = self._ctrl.get_port(cs)
        jedec = SerialFlashManager.read_jedec_id(spi)
        if not jedec:
            # it is likely that the latency setting is too low if this
            # condition is encountered
            raise SerialFlashUnknownJedec("Unable to read JEDEC Id")
        return SerialFlashManager._get_flash(spi, jedec)

    @staticmethod
    def read_jedec_id(spi):
        """Read flash device JEDEC identifier (3 bytes)"""
        jedec_cmd = Array('B', [SerialFlashManager.CMD_JEDEC_ID])
        return spi.exchange(jedec_cmd, 3).tostring()

    @staticmethod
    def _get_flash(spi, jedec):
		contents = sys.modules[__name__].__dict__
		devices = []
		plugin_dir = os.path.dirname(os.path.realpath(__file__))
		plugin_files = [x[:-3] for x in os.listdir(plugin_dir) if (x.endswith(".py") and not x.startswith("__init__"))]
		sys.path.insert(0, plugin_dir)
		for p in plugin_files:
			mod = __import__(p)
#			print "mod: " + str(mod)

			sf = getattr(mod, "SerialFlash")

#			for sp in sf.__subclasses__():
#				print "subclass: " + str(sp)


#			print "plugin file: " + str(p)
#			print "sf: " + str(sf)

			for name in dir (mod):
				if name.startswith('_'):
					continue
				obj = getattr(mod, name)

				if obj not in sf.__subclasses__():
					continue

#				for p in SerialFlash.__subclasses__():
#					print "subclass: " + p

#				print "name: " + name
#				print "base classes: " + str(inspect.getmro(obj))


#				print "\tclass: %s is class %s" % (str(obj), str(SerialFlash))

#				if not isinstance (obj, SerialFlash):
#					continue


#				if ("SerialFlash" in str(inspect.getmro(obj))):
#					print "found subclass"
#
#				for bn in inspect.getmro(obj):
#					print "base name: " + str(bn)

#
#				print "type: " + str(type(obj))
#				print "sf type: " + str(type(SerialFlash))
#

#				if  isclass(obj) and issubclass(obj, SerialFlash) and obj is not SerialFLash :
#				if  isclass(obj) and "SerialFLash" not in str(obj) :
#				print "\t\tappend name: " + name
				devices.append(obj)


		for device in devices:
			if device.match(jedec):
				return device(spi, jedec)
		raise SerialFlashUnknownJedec(jedec)



