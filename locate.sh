#!/usr/bin/env sh
# author: Tegan Burns
# website: teganburns.com

# Check README.md for details on how to get your API key
api_key="AIzaFyBwM79ERbyDMs_CVWt7T9DHxwAYvUmhHlk" 
url="https://www.googleapis.com/geolocation/v1/geolocate?key=$api_key"
json_file="result.json"
jqobj=""

# Remove old json_file
if [[ -e $json_file ]]; then
    rm $json_file
fi

#TODO: This may run into issues with mutiple WiFi devices
device=$( iw dev | sed '/Interface.*$/!d' | sed -e 's/^.*Interface //' )
scan=$( iw dev $device scan | sed -e 's/[ \t]*//' -e 's/[ \t]*$//' )

#BSS: xx:xx:xx:xx:xx:xx(dev whatever)
#signal: -77.00 dBm
#last seen: 1236 ms ago
#DS Parameter set: channel 36

# Filter out queries with sed
macAddr=($(echo "$scan" | sed -r -n 's/BSS ((([0-9a-fA-F]{2}):){5}([0-9a-fA-F]){2}).*$/\1/p' ))
signal=($(echo "$scan" | sed -r -n 's/signal: (-?[0-9]+)\.[0-9]* dBm/\1/p' ))
age=($(echo "$scan" | sed -r -n 's/last seen: ([0-9]*).*$/\1/p' ))
channel=($( echo "$scan" | sed -r -n 's/DS Parameter set: channel ([0-9]+)*.$/\1/p' | sed -r -e 's/^$/NULL/p'))


# Put all entries in JSON file
for i in ${!macAddr[@]}; do

    jqobj+="\"macAddress\": \"${macAddr[$i]}\", "
    jqobj+="\"signalStrength\": ${signal[$i]}, "

    # Ignore NULL key
    if [[ ${channel[$i]} == "NULL" ]]; then
        jqobj+="\"age\": ${age[$i]}"
    else
        jqobj+="\"age\": ${age[$i]}, "
        jqobj+="\"channel\": ${channel[$i]}"
    fi

    # Create new file if we need to
    if [[ ! -e $json_file ]]; then
        echo "{ \"considerIp\": \"false\", \"wifiAccessPoints\": [" > $json_file
    fi

    # If Last Obj for JSON file
    if [[ $i == $(( ${#macAddr[@]}  -1 )) ]]; then
        echo "{$jqobj}]}" >> $json_file
    else
        echo "{$jqobj}," >> $json_file
    fi

    jqobj=""
    continue;

    if [[ -e $json_file ]]; then
        jq -n $( echo "'{$jqobj}'") >> $json_file
    else
        jq -n $( echo "'{$jqobj}'") > $json_file
    fi


done

# Make Request
result=$(curl -s -d @$json_file -H "Content-Type: application/json" $url)
lat=$(echo "$result" | jq ' .location.lat')
lng=$(echo "$result" | jq ' .location.lng')

echo "https://www.google.com/maps/search/?api=1&query=$lat,$lng"
exit











