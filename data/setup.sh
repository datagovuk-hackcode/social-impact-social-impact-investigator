#!/bin/sh
./import.sh
pushd 2020wob
ruby scrape.rb
popd
pushd wegreen
ruby import.rb
popd
