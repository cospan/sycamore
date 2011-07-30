export PYTHONPATH=PYTHONPATH:./saplib:./saplib/sapgen:./data/gen_scripts
export SAPLIB_BASE=.

PYTHON_FILES = sapfile.py saplib.py
TEST_PYTHON_FILES = test_sapfile.py test_saplib.py

MODULES = ./data/gen_scripts


all:
	@for i in $(PYTHON_FILES); do \
		echo "building $$i"; \
		pycompile $$i; \
		done
	
	@for i in $(TEST_PYTHON_FILES); do \
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

test_gen:
	python test/test_sapgen.py

.PHONY: test_utils test_sap test_gen
