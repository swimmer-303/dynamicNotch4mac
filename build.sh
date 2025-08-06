#!/bin/bash

echo "Building DynamicNotch4Mac..."
swift build

if [ $? -eq 0 ]; then
    echo "Build successful! Running application..."
    swift run
else
    echo "Build failed!"
    exit 1
fi 