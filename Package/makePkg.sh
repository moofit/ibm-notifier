#!/bin/zsh
# shellcheck shell=bash

# Author:   Stephen Warneford-Bygrave - Moof IT
# Name:     makePkg.sh
# Version:  1.0.0
#
# Purpose:  This script makes a package of the IBM Notifier app, in /Applications/Utilities
#
# Usage:    Run in Terminal
#
# 1.0.0:    2022-01-23
#           SB - Initial Creation

# Use at your own risk. Moof IT will accept no responsibility for loss or damage caused by this script.

##### Declare functions

# Function to provide yes/no input

askYesNo()
{
    read -r ANSWER
    case "${ANSWER}" in

    [nN] | [nN][Oo])
        export YES_NO="no"
        ;;
    *)
        export YES_NO="yes"
        ;;
    esac
}

# This function outputs all variables set above to stdout and logger, as defined in the writelog function above

echoVariables()
{
    writelog "Log Process is ${LOG_PROCESS}"
}

# This function outputs help if either invoked manually or if an error occurs during input

showHelp()
{
    echo '
    Usage: /path/to/makePkg.sh [-v] -a "/path/to/IBM Notifier.app"

        -a | --app <path to app>    Mandatory; path to the IBM Notifier app bundle
        -v | --verbose              Verbose mode

    Examples:

        To run in Verbose mode
        
            /path/to/makePkg.sh -a "/Users/username/Documents/DerivedData/Build/IBM Notifier.app" -v
    '
    exit 1
}

# This function uses the native system logger to output events in this script.

writelog()
{
    # Write to system log
    /usr/bin/logger -is -t "${LOG_PROCESS}" "${1}"
}

##### Define Flags

# Use the total number of arguments provided at run time to determine the amount of iterations needed within the while
# loop (Note: The $# variable is equal to the total number of arguments provided to the script)

while [[ $# -gt 0 ]]; do
    case "${1}" in
    -a | --app)
        shift
        APP_LOCATION="${1}"
        ;;
    -v | --verbose)
        set -x
        ;;
    *)
        showHelp
        exit
        ;;
    esac
    shift
done

##### Set variables

LOG_PROCESS="makePkg"

##### Run script

echoVariables

if [[ ! -e "${APP_LOCATION}" || -z "${APP_LOCATION}" ]]; then
    writelog "App location not supplied or is incorrect. Please try again with the correct app location"
    showHelp
    exit 1
fi

# Find version and identifier
APP_VERSION=$(/usr/bin/defaults read "${APP_LOCATION}/Contents/Info.plist" CFBundleShortVersionString)
APP_IDENTIFIER=$(/usr/bin/defaults read "${APP_LOCATION}/Contents/Info.plist" CFBundleIdentifier)

# Make temp and build directories
TMP_DIR=$(/usr/bin/mktemp -d "/tmp/${LOG_PROCESS}.XXXX")
/bin/mkdir -p "${TMP_DIR}/build"

# Create requirements plist
cat >>"${TMP_DIR}/build/requirements.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>os</key>
    <array>
        <string>10.15.0</string>
    </array>
    <key>arch</key>
    <array>
        <string>x86_64</string>
        <string>arm64</string>
    </array>
</dict>
</plist>
EOF

# Remove any sort of quarantine
/usr/bin/xattr -cr "${TMP_DIR}"
/usr/bin/xattr -cr "${APP_LOCATION}"

# Create component package
/usr/bin/pkgbuild \
    --component "${APP_LOCATION}" \
    --install-location /Applications \
    --version "${APP_VERSION}" \
    --identifier "${APP_IDENTIFIER}" \
    "${TMP_DIR}/build/ibm_notifier.pkg"

# Create distribution file
/usr/bin/productbuild \
    --package "${TMP_DIR}/build/ibm_notifier.pkg" \
    --product "${TMP_DIR}/build/requirements.plist" \
    "${TMP_DIR}/IBM Notifier-${APP_VERSION}.pkg"

# echo ""
# echo "Do you want to sign the installer (Y/n)?"
# askYesNo
# if [[ ${YES_NO} == "yes" ]]; then

#     # Sign the installer
#     sign "${TMP_DIR}/IBM Notifier-${APP_VERSION}.pkg"
# fi

echo ""
echo "Do you want to copy the installer to your desktop (Y/n)?"
askYesNo
if [[ ${YES_NO} == "yes" ]]; then

    # Copy to desktop
    cp "${TMP_DIR}/IBM Notifier-${APP_VERSION}.pkg" ~/"Desktop"
fi
