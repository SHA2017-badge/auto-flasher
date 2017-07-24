#!/usr/bin/env bash

set -e

cd firmware/locfd

for type in sl n; do
	cp media/hacking-$type.png media/hacking.png

	# create with maximum compression to a temporary file.
	zip -r -9 ../locfd-$type.zip.$$ .

	rm media/hacking.png

	# always do an atomic move.
	mv ../locfd-$type.zip.$$ ../locfd-$type.zip
done
