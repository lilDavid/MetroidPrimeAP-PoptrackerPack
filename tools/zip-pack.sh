#!/bin/sh

mkdir -p output

rm -f MetroidPrimeAP_PopTrackerPack.zip MetroidPrime-Archipelago-lilDavid.zip
rm -rf output/*

files="images items layouts locations maps scripts var_* manifest.json settings.json"
cp -r $files output

cd output
zip -r ../MetroidPrime-Archipelago-lilDavid.zip * -x "**/.DS_Store"
