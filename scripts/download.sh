#!/bin/sh

# download.sh
# setup-xcode-simulator • https://github.com/orchetect/setup-xcode-simulator
# © 2026 Steffan Andrews • Licensed under MIT License

# setup-xcode-simulator

# Workaround for Xcode/GitHub runner issues finding simulators.
# see https://github.com/actions/runner-images/issues/12758#issuecomment-3206748945

# Inputs:
# - SIMPLATFORM_SHORT    required

# Step outputs produced:
# (none)

echo "Downloading simulator if needed..."

# Capture output so it doesn't spam the console. In future this can optionally be printed to the console.
LOG=$(xcodebuild -downloadPlatform "$SIMPLATFORM_SHORT")

echo "Done downloading simulator."
