#!/bin/sh

PACK_NAME=MetroidPrime-Archipelago-lilDavid.zip

mkdir -p output

rm -f MetroidPrimeAP_PopTrackerPack.zip "$PACK_NAME"
rm -rf output/*

files="images items layouts locations maps scripts var_* manifest.json settings.json"
cp -r $files output

cd output
zip -r "../$PACK_NAME" * -x "**/.DS_Store"

echo
cd ..
sha256sum "$PACK_NAME"
