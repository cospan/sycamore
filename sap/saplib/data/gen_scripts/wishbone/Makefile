
FILES = gen_interconnect

all:
	@for i in $(FILES); do \
		echo "Compiling $$i" ; \
		pycompile $$i.py ; \
		echo "Copying modules to gen_modules directory"; \
		mv ./$$i.pyc ../../gen_modules/ ; \
		done 
		
.PHONY: all

