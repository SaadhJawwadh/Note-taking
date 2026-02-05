#!/bin/bash

# Simple script to bump version numbers
# Usage: ./bump_version.sh 1.8.0 1

NEW_VERSION=$1
BUILD_NUMBER=$2

if [ -z "$NEW_VERSION" ] || [ -z "$BUILD_NUMBER" ]; then
  echo "Usage: ./bump_version.sh <version> <build_number>"
  echo "Example: ./bump_version.sh 1.8.1 2"
  exit 1
fi

# Update pubspec.yaml
sed -i '' "s/version: .*/version: $NEW_VERSION+$BUILD_NUMBER/" pubspec.yaml

echo "Updated to $NEW_VERSION+$BUILD_NUMBER"
