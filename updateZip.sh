#!/usr/bin/env bash

set -e

cd firmware/locfd

for type in sl n f; do
	cp media/badge_type_$type.png media/badge_type.png

	# create with maximum compression to a temporary file.
	zip -r -9 ../locfd-$type.zip.$$ . -x .ds_store

	rm media/badge_type.png

	# always do an atomic move.
	mv ../locfd-$type.zip.$$ ../locfd-$type.zip
done
