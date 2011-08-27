
SUBDIRS = wishbone xilinx

all:
	@for i in $(SUBDIRS); do \
	echo "changing to: $$i..."; \
	(cd $$i; make all); done
	pycompile gen.py
	mv gen.pyc ../gen_modules/


.PHONY: all
	
