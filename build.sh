#!/bin/bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

#
# Super minimal script to build an Xcode iOS project and zip up the .app file as an .ipa file
#
# build.sh <target> <configuration> [extra arguments for xcodebuild...]
#

TARGET=$1
CONFIGURATION=$2

rm -rf build
xcodebuild -target "$TARGET" -configuration "$CONFIGURATION" "${@:3}" || exit 1

mkdir build/Payload || exit 1
mv "build/$CONFIGURATION-iphoneos/$TARGET.app" build/Payload/ || exit 1
jar cvf "build/$TARGET.ipa" -C build Payload || exit 1

