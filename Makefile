all: docs

docs:
	rm -rf doc ; cd lib ; rdoc -d -p -S -a -N -o ../doc
