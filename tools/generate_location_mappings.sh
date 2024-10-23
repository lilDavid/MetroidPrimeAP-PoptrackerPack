#!/bin/sh

# Uses grep and sed to generate the location autotracking mappings as a Lua table
# Currently generates wrong location mappings since we need names for all sections

if [[ "$#" -lt 1 ]]; then
    >&2 echo "Usage: $0 apworld-path"
    exit 1
fi

name="[A-Za-z ]+"
location_name="'($name): ($name)( - ([A-Za-z -]+))?': ([0-9]+),?"

exec 3> scripts/autotracking/location_mapping.lua
echo 'LOCATION_MAPPING = {' >&3
grep -E "$location_name" "$1/Locations.py" | sed -E "s|$location_name|[\\5] = {\"@\\1/\\2/\\4\"},|" >&3
echo '}' >&3
exec 3>&-

