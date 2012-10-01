#!/usr/bin/env bash

# prerequisite:
# npm install jasmine-node

echo "Running all tests located in the spec directory"
command="jasmine-node --coffee src/spec/coffee"
echo $command
time $command