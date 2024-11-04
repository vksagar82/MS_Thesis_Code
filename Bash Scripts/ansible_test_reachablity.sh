#!/bin/bash  
printf "%-20s %-10s\n" "HOSTNAME" "STATUS"  
printf "%-20s %-10s\n" "--------" "------"  
for host in $(ansible all --list-hosts | grep -v "hosts"); do  
    if ansible $host -m shell -a "ping -c 1 {{ ansible_host }}" &>/dev/null; then  
        printf "%-20s \033[0;32m%-10s\033[0m\n" "$host" "UP"  
    else  
        printf "%-20s \033[0;31m%-10s\033[0m\n" "$host" "DOWN"  
    fi  
done