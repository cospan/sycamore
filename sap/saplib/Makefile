export PYTHONPATH=PYTHONPATH:./saplib:./saplib/sapgen:./data/gen_modules
export SAPLIB_BASE=$(PWD)

PYTHON_FILES = sapfile.py sapproject.py saplib.py saputils.py
TEST_PYTHON_FILES = test_sapfile.py test_sapproject.py test_saplib.py test_saputils.py test_interconnect.py

MODULES = ./data/gen_scripts


all:
	@for i in $(PYTHON_FILES); do \
		echo "building $$i"; \
		pycompile $$i; \
		done

gen_modules:
	@for i in $(MODULES); do \
		echo "building modules in $$i..."; \
		(cd $$i; make all); \
		done
	
test_all:
	@for i in $(TEST_PYTHON_FILES); do \
		echo "testing $$i"; \
		python test/$$i; \
		done

test_utils:
	python test/test_saputils.py

test_sap:
	python test/test_saplib.py

test_file:
	python test/test_sapfile.py

test_project:
	python test/test_sapproject.py

test_interconnect:
	python test/test_interconnect.py 

test_help:
	echo $(PWD)

.PHONY: test_utils test_sap test_gen
