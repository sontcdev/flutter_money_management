#!/bin/bash

# Script to increment patch version in pubspec.yaml
# Example: 1.0.7 -> 1.0.8

PUBSPEC="pubspec.yaml"

# Read current version from pubspec.yaml
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC" | sed 's/version: //')

echo "Current version: $CURRENT_VERSION"

# Parse version (format: major.minor.patch)
IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"

# Increment patch version
NEW_PATCH=$((PATCH + 1))
NEW_VERSION="$MAJOR.$MINOR.$NEW_PATCH"

echo "New version: $NEW_VERSION"

# Update pubspec.yaml
sed -i "s/^version: $CURRENT_VERSION/version: $NEW_VERSION/" "$PUBSPEC"

echo "Version updated successfully!"
exit 0
