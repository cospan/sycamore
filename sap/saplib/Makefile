export PYTHONPATH=PYTHONPATH:./saplib:./saplib/sapgen

all:
	pycompile saputils.py
	pycompile saplib.py
	pycompile sapgen/sapgen.py
	pycompile test/test_sapgen.py
	pycompile test/test_saplib.py
	pycompile test/test_saputils.py

test_utils:
	python test/test_saputils.py

test_sap:
	python test/test_saplib.py

test_gen:
	python test/test_sapgen.py


