export PYTHONPATH=PYTHONPATH:../saplib/saplib:../saplib/saplib/sapgen:../saplib/data/gen_modules 
export SAPLIB_BASE=$(PWD)/../saplib

PYTHON_FILES = sapcmd.py
TEST_PYTHON_FILES = test_sapcmd.py

all:
	@for i in $(PYTHON_FILES); do \
		echo "building $$i"; \
		pycompile $$i; \
		done

test_sapcmd:
	python test/test_sapcmd.py


.PHONY: test_sapcmd
