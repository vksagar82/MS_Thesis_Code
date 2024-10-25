#!/bin/bash  

# Check if a target is provided  
if [ $# -eq 0 ]; then  
    echo "Usage: sudo $0 <salt_target>"  
    echo "Example: sudo $0 'juniper1-65001' or sudo $0 'juniper*-65001' or sudo $0 '*'"  
    exit 1  
fi  

# Salt target passed as an argument  
SALT_TARGET="$1"  

# Function to extract destination IPs from yaml file  
extract_ips() {  
    python3 -c "  
import yaml, sys  

try:  
    with open('dst_ip.yml', 'r') as file:  
        data = yaml.safe_load(file)  
    ips = data['dest_addr']['ip_details']['dst']  
    print(' '.join(map(str, ips)))  
except Exception as e:  
    print(f'Error: {str(e)}', file=sys.stderr)  
"  
}  

# Function to extract source IPs from loopback configuration  
extract_src_ips() {  
    python3 -c "  
import json, sys  

def extract_ips(data):  
    ips = []  
    if isinstance(data, dict):  
        for interface in data.values():  
            if isinstance(interface, list):  
                ips.extend(config['ip'] for config in interface if 'ip' in config)  
            elif isinstance(interface, dict) and 'ip' in interface:  
                ips.append(interface['ip'])  
    elif isinstance(data, list):  
        ips.extend(config['ip'] for config in data if 'ip' in config)  
    return ips  

try:  
    data = json.load(sys.stdin)  
    for minion, configs in data.items():  
        print(' '.join(extract_ips(configs)))  
except json.JSONDecodeError:  
    print('Error: Invalid JSON data', file=sys.stderr)  
except Exception as e:  
    print(f'Error: {str(e)}', file=sys.stderr)  
"  
}  

# Get the source IPs from loopback configurations  
src_ips=$(salt -E "$SALT_TARGET" pillar.get 'loopback_configs' --out=json 2>/dev/null | extract_src_ips)  
dst_ips=$(extract_ips)  

# Check if we got any IPs  
if [ -z "$src_ips" ] || [ -z "$dst_ips" ]; then  
    echo "Error: Failed to retrieve IP addresses."  
    echo "Source IPs: $src_ips"  
    echo "Destination IPs: $dst_ips"  
    echo "Raw Salt output for source IPs:"  
    salt -E "$SALT_TARGET" pillar.get 'loopback_configs' --out=json  
    echo "Contents of dst_ip.yml:"  
    cat dst_ip.yml  
    exit 1  
fi  

# If src_ips is empty, use the first IP from dst_ips as the source  
if [ -z "$src_ips" ]; then  
    src_ips=$(echo $dst_ips |awk '{print $1}')  
    echo "Warning: No source IPs found. Using the first destination IP as the source: $src_ips"  
fi  

# Print the retrieved IPs for debugging  
echo "Source IPs: $src_ips"  
echo "Destination IPs: $dst_ips"  

# Initialize counters  
total_pings=0  
successful_pings=0  
failed_pings=0  

# Print table header  
printf "+--------------+--------------+--------+----------+----------+----------+----------+\n"  
printf "| %-12s | %-12s | %-6s | %-8s | %-8s | %-8s | %-8s |\n" "Source IP" "Destination IP" "Result" "Min RTT" "Avg RTT" "Max RTT" "Loss"  
printf "+--------------+--------------+--------+----------+----------+----------+----------+\n"  

# Loop through each source IP  
for src in $src_ips; do  
    # Loop through each destination IP  
    for dst in $dst_ips; do  
        # Perform the ping and capture the full output  
        full_output=$(salt -E "$SALT_TARGET" net.ping $dst source=$src timeout=1 count=1 --out=yaml 2>&1)  
        
        # Extract relevant information  
        if echo "$full_output" | grep -q "result: true"; then  
            if echo "$full_output" | grep -q "error:"; then  
                # Juniper failure case  
                status="Failed"  
                rtt_min="-"  
                rtt_avg="-"  
                rtt_max="-"  
                packet_loss="100"  
                ((failed_pings++))  
            else  
                # Success case (both Cisco and Juniper)  
                status="Success"  
                rtt_min=$(echo "$full_output" | grep -oP 'rtt_min: \K[0-9.]+')  
                rtt_avg=$(echo "$full_output" | grep -oP 'rtt_avg: \K[0-9.]+')  
                rtt_max=$(echo "$full_output" | grep -oP 'rtt_max: \K[0-9.]+')  
                packet_loss=$(echo "$full_output" | grep -oP 'packet_loss: \K[0-9]+')  
                
                # Check if all RTT values are 0.0 (Cisco failure case)  
                if [[ "$rtt_min" == "0.0" && "$rtt_avg" == "0.0" && "$rtt_max" == "0.0" ]]; then  
                    status="Failed"  
                    rtt_min="-"  
                    rtt_avg="-"  
                    rtt_max="-"  
                    ((failed_pings++))  
                else  
                    ((successful_pings++))  
                fi  
            fi  
        else  
            # Unexpected failure case  
            status="Failed"  
            rtt_min="-"  
            rtt_avg="-"  
            rtt_max="-"  
            packet_loss="100"  
            ((failed_pings++))  
        fi  
        
        # Print result in table format  
        printf "| %-12s | %-12s | %-6s | %-8s | %-8s | %-8s | %-7s%% |\n" \
               "$src" "$dst" "$status" "$rtt_min" "$rtt_avg" "$rtt_max" "$packet_loss"  
        
        ((total_pings++))  
    done  
done  

# Print table footer  
printf "+--------------+--------------+--------+----------+----------+----------+----------+\n"  

# Print summary  
echo  
echo "Summary:"  
echo "Total pings: $total_pings"  
echo "Successful pings: $successful_pings"  
echo "Failed pings: $failed_pings"  
if [ $total_pings -gt 0 ]; then  
    echo "Success rate: $(( (successful_pings * 100) / total_pings ))%"  
else  
    echo "Success rate: N/A (no pings performed)"  
fi
