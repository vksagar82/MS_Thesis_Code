#!/bin/bash  

# Path to the top.sls file  
TOP_FILE="/etc/salt/pillar/top.sls"  

# Check if the file exists  
if [ ! -f "$TOP_FILE" ]; then  
    echo "Error: $TOP_FILE does not exist."  
    exit 1  
fi  

# Extract device names from the top.sls file  
DEVICES=$(grep -oP "'\K[^']+(?=')" "$TOP_FILE" | sort | uniq)  

# Loop through each device  
for device in $DEVICES  
do  
    # Check if the proxy for this device is already running  
    if pgrep -f "salt-proxy.*--proxyid $device" > /dev/null  
    then  
        echo "Proxy for $device is already running."  
    else  
        echo "Starting proxy for $device"  
        sudo salt-proxy -d --proxyid $device  
    fi  
done  

echo "All devices enabled."
