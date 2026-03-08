#!/usr/bin/env bash
#
# Note that GitHub Actions DO NOT USE THE ZSH SHELL, YOU MUST USE BASH (still as of Mar 2026).
# This script is confirmed to work on both bash and zsh.
#
# References:
# GitHub composite action documentation:
# - https://docs.github.com/en/actions/tutorials/create-actions/create-a-composite-action
# GitHub Actions exit codes:
# - https://docs.github.com/en/actions/how-tos/create-and-publish-actions/set-exit-codes

# Inputs:
# - INPUT_WORKSPACEPATH  optional
# - INPUT_SCHEME         required
# - INPUT_TARGET         required
# - INPUT_OSVERSION      optional

# Setup workspace path.
if [[ -z $INPUT_WORKSPACEPATH ]]; then
  # If variable is empty or not set, assume the repo is a Swift Package with the Package.swift file located in the root of the repo.
  WORKSPACEPATH=".swiftpm/xcode/package.xcworkspace"
else
  WORKSPACEPATH="$INPUT_WORKSPACEPATH"
fi

# Provide diagnostic output of workspace path.
echo "Using workspace path: $WORKSPACEPATH"

# Setup Xcode scheme.
SCHEME="$INPUT_SCHEME"

# Validate platform.
# Convert input to lowercase to enable "case-insensitive" matching.
INPUT_TARGET_LOWERCASE=$( tr '[:upper:]' '[:lower:]' <<<"$INPUT_TARGET" )
case $INPUT_TARGET_LOWERCASE in
  ios)
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPhone\s\d{2}\s"
    ;;

  tvos)
    SIMPLATFORM_REGEX="tvOS"
    SIMDEVICE_REGEX="AppleTV"
    ;;

  watchos)
    SIMPLATFORM_REGEX="watchOS"
    SIMDEVICE_REGEX="Apple\sWatch\sSeries"
    ;;

  visionos)
    SIMPLATFORM_REGEX="visionOS"
    SIMDEVICE_REGEX="Apple\sVision\sPro"
    ;;

  iphone)
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPhone\s\d{2}\s"
    ;;
  
  iphone-air)
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPhone\sAir"
    ;;
  
  iphone-pro)
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPhone\s\d{2}\sPro\s"
    ;;
  
  iphone-pro-max)
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPhone\s\d{2}\sPro\sMax"
    ;;
  
  ipad)
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPad\s"
    ;;
  
  ipad-air)
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPad\sAir"
    ;;
  
  ipad-pro)
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPad\sPro"
    ;;
  
  ipad-mini)
    SIMPLATFORM_REGEX="iOS"
    SIMDEVICE_REGEX="iPad\smini"
    ;;
  
  tv)
    SIMPLATFORM_REGEX="tvOS"
    SIMDEVICE_REGEX="AppleTV"
    ;;
  
  tv-4k)
    SIMPLATFORM_REGEX="tvOS"
    SIMDEVICE_REGEX="AppleTV\s4K"
    ;;
  
  watch)
    SIMPLATFORM_REGEX="watchOS"
    SIMDEVICE_REGEX="Apple\sWatch"
    ;;
  
  watch-se)
    SIMPLATFORM_REGEX="watchOS"
    SIMDEVICE_REGEX="Apple\sWatch\sSE"
    ;;
  
  watch-series)
    SIMPLATFORM_REGEX="watchOS"
    SIMDEVICE_REGEX="Apple\sWatch\sSeries"
    ;;
  
  watch-ultra)
    SIMPLATFORM_REGEX="watchOS"
    SIMDEVICE_REGEX="Apple\sWatch\sUltra"
    ;;
    
  visionpro)
    SIMPLATFORM_REGEX="visionOS"
    SIMDEVICE_REGEX="Apple\sVision\sPro"
    ;;
  
  visionpro-4k)
    SIMPLATFORM_REGEX="visionOS"
    SIMDEVICE_REGEX="Apple\sVision\sPro\s4K"
    ;;
  
  *)
    # Check for empty string
    if [[ -z $INPUT_TARGET ]]; then echo "Error: No target specified."; exit 1; fi
    
    # Otherwise, use target as device name regex.
    SIMPLATFORM_REGEX=".*" # Act as a pass-thru for platform matches.
    SIMDEVICE_REGEX="$SIMPLATFORM"
    echo "Using target string as device name regex: $SIMDEVICE_REGEX"
    ;;
esac

# Setup OS version scheme.
SIMOS_REGEX="$INPUT_OSVERSION"

# Get full list of all available device simulators installed in the system that are applicable for the given Xcode scheme.
XCODE_OUTPUT=$(xcodebuild -showdestinations -workspace "$WORKSPACEPATH" -scheme "$SCHEME")
XCODE_OUTPUT_REGEX="m/\{\splatform:(.*\sSimulator),.*id:([A-F0-9\-]{36}),.*OS:(\d{1,2}\.\d),.*name:([a-zA-Z0-9\(\)\s]*)\s\}/g"

# Provide diagnostic output of device list matching the specified platform and device.
SIMPATFORM_LIST_PREVIEW=$(echo "${XCODE_OUTPUT}" | perl -nle 'if ('$XCODE_OUTPUT_REGEX') { ($plat, $id, $os, $name) = ($1, $2, $3, $4); if ($plat =~ /'$SIMPLATFORM_REGEX'/ and $name =~ /'$SIMDEVICE_REGEX'/) { print "- ${name} (${plat} - ${os}) - ${id}"; } }')
if [[ -z $SIMPATFORM_LIST_PREVIEW ]]; then echo "Error: no matching simulators available."; exit 1; fi
echo "Available simulators matching the target:"
echo "$SIMPATFORM_LIST_PREVIEW"

# Parse device list into a format that is easier to parse out.
SIMPLATFORMS=$(echo "${XCODE_OUTPUT}" | perl -nle 'if ('$XCODE_OUTPUT_REGEX') { ($plat, $id, $os, $name) = ($1, $2, $3, $4); if ($plat =~ /'$SIMPLATFORM_REGEX'/ and $name =~ /'$SIMDEVICE_REGEX'/) { print "${name}\t${plat}\t${os}\t${id}"; } }' | sort -rV)
SIMPLATFORMS_REGEX="m/(.*)\t(.*)\t(.*)\t(.*)/g"

# Find simulator ID
if [[ -n $SIMOS_REGEX ]]; then
  echo "Finding OS version using regex: ${SIMOS_REGEX}."
  DESTID=$(echo "${SIMPLATFORMS}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); if ($os =~ /'$SIMOS_REGEX'/) { print "${id}"; } }' | head -n 1)
  DESTDESC=$(echo "${SIMPLATFORMS}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); if ($os =~ /'$SIMOS_REGEX'/) { print "${name} (${plat} - ${os}) - ${id}"; } }' | head -n 1)
else
  echo "Finding latest OS version for target."
  LINE=$(echo "${SIMPLATFORMS}" | head -1)
  DESTID=$(echo "${LINE}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); print $id; }')
  DESTDESC=$(echo "${LINE}" | perl -nle 'if ('$SIMPLATFORMS_REGEX') { ($name, $plat, $os, $id) = ($1, $2, $3, $4); print "${name} (${plat} - ${os}) - ${id}"; }')
fi

# Exit out if no simulators matched the criteria.
if [[ -z $DESTID ]]; then echo "Error: No matching simulators available."; exit 1; fi

# Provide diagnostic output of selected devince simulator info.
echo "Found device simulator: $DESTDESC"

# Set output variable.
echo "id=$(echo $DESTID)" >> $GITHUB_OUTPUT
