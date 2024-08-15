#!/bin/sh

mkdir -p output

rm -f MetroidPrimeAP_PopTrackerPack.zip
rm -rf output/*

files="images items layouts locations maps scripts var_* manifest.json settings.json"
cp -r $files output

cd output
zip -r ../MetroidPrimeAP_PopTrackerPack.zip * -x "**/.DS_Store"
