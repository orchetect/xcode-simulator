#!/bin/sh

# refresh.sh
# setup-xcode-simulator • https://github.com/orchetect/setup-xcode-simulator
# © 2026 Steffan Andrews • Licensed under MIT License

# Workaround for Xcode/GitHub runner issues finding simulators.
# see https://github.com/actions/runner-images/issues/12758#issuecomment-3206748945

# Inputs:
# (none)

# Step outputs produced:
# (none)

echo "Refreshing simulators..."

# Capture output so it doesn't spam the console. In future this can optionally be printed to the console.
LIST=$(xcrun simctl list)

echo "Done refreshing simulators."