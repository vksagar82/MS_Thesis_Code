#!/bin/bash  

# Function to parse YAML file and extract IPs  
parse_yaml() {  
    python3 -c '  
import yaml  
import sys  
with open("'"$1"'", "r") as file:  
    data = yaml.safe_load(file)  
    for ip in data["dest_addr"]["ip_details"]["dst"]:  
        print(ip)  
'  
}  

# Function to extract source IPs from host vars  
get_source_ips() {  
    python3 -c '  
import yaml  
import sys  
with open("'"$1"'", "r") as file:  
    data = yaml.safe_load(file)  
    ips = []  
    # Process loopback0  
    if "loopback0" in data["loopback_configs"]:  
        for loopback in data["loopback_configs"]["loopback0"]:  
            ips.append(loopback["ip"])  
    
    # Process loopback1 if it exists  
    if "loopback1" in data["loopback_configs"]:  
        for loopback in data["loopback_configs"]["loopback1"]:  
            ips.append(loopback["ip"])  
    
    print("\n".join(ips))  
'  
}  

# Function to get ping command based on device type  
get_ping_command() {  
    local device=$1  
    local dst_ip=$2  
    local src_ip=$3  
    
    if [[ $device == *"juniper"* ]]; then  
        echo "ansible -i hosts $device -m cli_command -a \"command='ping $dst_ip source $src_ip count 5 rapid'\""  
    elif [[ $device == *"cisco"* ]]; then  
        echo "ansible -i hosts $device -m cli_command -a \"command='ping $dst_ip source $src_ip repeat 5 timeout 1'\""  
    elif [[ $device == *"arista"* ]]; then  
        echo "ansible -i hosts $device -b -m cli_command -a \"command='ping $dst_ip source $src_ip repeat 5 timeout 1'\""  
    else  
        echo "Unknown device type"  
        return 1  
    fi  
}  

# Function to extract RTT values and packet loss from ping output  
parse_ping_output() {  
    local output="$1"  
    local device_type="$2"  
    local result=""  
    local min_rtt=""  
    local avg_rtt=""  
    local max_rtt=""  
    local loss=""  

    # Check for ansible errors or no response  
    if [[ $output =~ "ERROR" || $output =~ "FAILED" || -z "$output" ]]; then  
        result="Failed"  
        loss="100%"  
        min_rtt="-"  
        avg_rtt="-"  
        max_rtt="-"  
        echo "$result|$min_rtt|$avg_rtt|$max_rtt|$loss"  
        return  
    fi  

    case $device_type in  
        "juniper")  
            if echo "$output" | grep -q "0% packet loss"; then  
                result="Success"  
                rtt_line=$(echo "$output" | grep "round-trip min/avg/max")  
                if [[ $rtt_line =~ min/avg/max/stddev[[:space:]]*=[[:space:]]*([0-9.]+)/([0-9.]+)/([0-9.]+) ]]; then  
                    min_rtt="${BASH_REMATCH[1]}"  
                    avg_rtt="${BASH_REMATCH[2]}"  
                    max_rtt="${BASH_REMATCH[3]}"  
                fi  
                loss="0%"  
            else  
                result="Failed"  
                if [[ $output =~ ([0-9]+)%[[:space:]]*packet[[:space:]]*loss ]]; then  
                    loss="${BASH_REMATCH[1]}%"  
                else  
                    loss="100%"  
                fi  
                min_rtt="-"  
                avg_rtt="-"  
                max_rtt="-"  
            fi  
            ;;  
        "cisco")  
            if echo "$output" | grep -q "Success rate is 100"; then  
                result="Success"  
                if [[ $output =~ min/avg/max[[:space:]]*=[[:space:]]*([0-9]+)/([0-9]+)/([0-9]+) ]]; then  
                    min_rtt="${BASH_REMATCH[1]}"  
                    avg_rtt="${BASH_REMATCH[2]}"  
                    max_rtt="${BASH_REMATCH[3]}"  
                fi  
                loss="0%"  
            else  
                result="Failed"  
                if [[ $output =~ Success[[:space:]]+rate[[:space:]]+is[[:space:]]+([0-9]+)[[:space:]]+percent ]]; then  
                    loss="$((100-${BASH_REMATCH[1]}))%"  
                else  
                    loss="100%"  
                fi  
                min_rtt="-"  
                avg_rtt="-"  
                max_rtt="-"  
            fi  
            ;;  
        "arista")  
            if echo "$output" | grep -q "0% packet loss"; then  
                result="Success"  
                if [[ $output =~ min/avg/max[[:space:]]*=[[:space:]]*([0-9.]+)/([0-9.]+)/([0-9.]+) ]]; then  
                    min_rtt="${BASH_REMATCH[1]}"  
                    avg_rtt="${BASH_REMATCH[2]}"  
                    max_rtt="${BASH_REMATCH[3]}"  
                fi  
                loss="0%"  
            else  
                result="Failed"  
                if [[ $output =~ ([0-9]+)%[[:space:]]*packet[[:space:]]*loss ]]; then  
                    loss="${BASH_REMATCH[1]}%"  
                else  
                    loss="100%"  
                fi  
                min_rtt="-"  
                avg_rtt="-"  
                max_rtt="-"  
            fi  
            ;;  
    esac  

    echo "$result|$min_rtt|$avg_rtt|$max_rtt|$loss"  
}  

# Check if device argument is provided  
if [ -z "$1" ]; then  
    echo "Please provide device name as argument"  
    exit 1  
fi  

DEVICE=$1  

# Determine device type  
if [[ $DEVICE == *"juniper"* ]]; then  
    DEVICE_TYPE="juniper"  
elif [[ $DEVICE == *"cisco"* ]]; then  
    DEVICE_TYPE="cisco"  
elif [[ $DEVICE == *"arista"* ]]; then  
    DEVICE_TYPE="arista"  
else  
    echo "Unknown device type"  
    exit 1  
fi  

# Get source IPs from host_vars file  
HOST_FILE="/etc/ansible/host_vars/$DEVICE.yml"  
if [ ! -f "$HOST_FILE" ]; then  
    echo "Host file not found: $HOST_FILE"  
    exit 1  
fi  

# Extract source IPs from host file  
SRC_IPS=$(get_source_ips "$HOST_FILE")  

if [ -z "$SRC_IPS" ]; then  
    echo "Could not find source IPs in host file"  
    exit 1  
fi  

# Initialize counters  
total_pings=0  
successful_pings=0  

# Print table header  
printf "+--------------+--------------+--------+----------+----------+----------+----------+\n"  
printf "| %-12s | %-12s | %-6s | %-8s | %-8s | %-8s | %-8s |\n" "Source IP" "Destination IP" "Result" "Min RTT" "Avg RTT" "Max RTT" "Loss"  
printf "+--------------+--------------+--------+----------+----------+----------+----------+\n"  

# Get destination IPs  
dst_ips=$(parse_yaml "/etc/ansible/dst_ip.yml")  

# Process each source IP  
while read -r src_ip; do  
    # Process each destination IP  
    while read -r dst_ip; do  
        # Get and execute ping command  
        cmd=$(get_ping_command "$DEVICE" "$dst_ip" "$src_ip")  
        output=$(eval "$cmd")  
        
        # Parse output  
        parsed_output=$(parse_ping_output "$output" "$DEVICE_TYPE")  
        IFS='|' read -r result min_rtt avg_rtt max_rtt loss <<< "$parsed_output"  

        # Print result row  
        printf "| %-12s | %-12s | %-6s | %-8s | %-8s | %-8s | %-8s |\n" \
            "$src_ip" "$dst_ip" "$result" "$min_rtt" "$avg_rtt" "$max_rtt" "$loss"  

        # Update counters  
        ((total_pings++))  
        [[ $result == "Success" ]] && ((successful_pings++))  

    done <<< "$dst_ips"  
done <<< "$SRC_IPS"  

# Print table footer  
printf "+--------------+--------------+--------+----------+----------+----------+----------+\n"  

# Print summary  
echo  
echo "Summary:"  
echo "Total pings: $total_pings"  
echo "Successful pings: $successful_pings"  
echo "Failed pings: $((total_pings - successful_pings))"  
if [ $total_pings -gt 0 ]; then  
    echo "Success rate: $(( (successful_pings * 100) / total_pings ))%"  
fi
