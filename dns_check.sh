#!/bin/bash

if [ -n "$1" ];then
    DOMAIN="$1"
else
    echo "Provide domain name as argument."
    exit 1
fi

MY_DNS_IP=$(nslookup $DOMAIN|grep -i "^server:\s\+"|grep -o "[1-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*")

TRUSTED_SERVERS=("8.8.8.8" "1.1.1.1" "9.9.9.9" "$MY_DNS_IP")
DECLARED_IP=""  # Expected IP (optional, if known)

echo "Checking DNS responses for domain: $DOMAIN"
echo

declare -A responses

# Query each trusted server
for server in "${TRUSTED_SERVERS[@]}"; do
    response=$(dig @$server +short $DOMAIN | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$')
    responses[$server]=$response
    echo "DNS Server: $server -> $response"
done

# Compare results
echo
echo "Analyzing results..."
unique_ips=($(printf "%s\n" "${responses[@]}" | sort -u))
if [ ${#unique_ips[@]} -gt 1 ]; then
    echo "Potential DNS poisoning detected! Multiple IPs returned:"
    printf "%s\n" "${unique_ips[@]}"
else
    echo "All responses match: ${unique_ips[0]}"
fi

# Check against a declared IP (optional)
if [ -n "$DECLARED_IP" ]; then
    if [[ " ${unique_ips[@]} " =~ ${DECLARED_IP} ]]; then
        echo "The declared IP ($DECLARED_IP) matches the responses."
    else
        echo "Declared IP ($DECLARED_IP) does not match the responses!"
    fi
fi
