#!/usr/bin/env bash

set -e

cd firmware/locfd

# create with maximum compression to a temporary file.
zip -r -9 ../locfd.zip.$$ .

cd ..

# always do an atomic move.
mv locfd.zip.$$ locfd.zip
