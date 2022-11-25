#!/bin/bash
# initial data; they need to be filled by the user
## user domain; e.g. example in case of example.duckdns.org
user_domain=
## unique token in duckDNS account, sign-in to fetch it e.g. aaaabbbb-cccc-4444-8888-ddeeff001122
token=
## the dns record (sub-domain) that needs to be modified; e.g. sub.example.com
dns_record=
## Update output detailed true / false
# verb='true'

# Check if the script is already running
# if [ ps ax | grep $0 | grep -v $$ | grep bash | grep -v grep ]; then
#     echo -e "\033[0;31m [-] The script is already running."
#     exit 1
# fi

###  Create .update-cloudflare-dns.log file of the last run for debug
parent_path="$(dirname "${BASH_SOURCE[0]}")"
FILE=${parent_path}/duckdns_local.log
if ! [ -x "$FILE" ]; then
  touch "$FILE"
fi

STOREFILE=${parent_path}/ddnsipstore.txt
if ! [ -x "$STOREFILE" ]; then
  touch "$STOREFILE"
fi

LOG_FILE=${parent_path}'/duckdns_local.log'
IP_STORE_FILE=${parent_path}'/ddnsipstore.txt'

### Write last run of STDOUT & STDERR as log file and prints to screen
exec > >(tee $LOG_FILE) 2>&1
echo "==> $(date "+%Y-%m-%d %H:%M:%S")"


# Check if DNS Records Exists
#check_record_ipv4=$(dig -t a +short ${dns_record} | tail -n1)
check_record_ipv6=$(dig -t aaaa +short ${dns_record} | tail -n1)

if [ -z "${check_record_ipv6}" ]; then
    echo -e "\033[0;31m [-] global ipv6 is not assigned, need to restart network services and Server (Android) should be screen on mode"
    exit 1
fi

old_ipv6=$(cat $IP_STORE_FILE)

current_ipv6=$(ip -6 addr show dev wlan0 scope global temporary dynamic | sed -e'2 s/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d')

if [ -z "${old_ipv6}" ]; then
    echo "$current_ipv6" > $IP_STORE_FILE
    echo -e "\033[0;37m [~] Script probably run for first time so no old record exist, Skipping update of IP in DuckDNS"
    exit 1
fi

if [ $old_ipv6 != $current_ipv6 ]; then
                echo -e "\033[0;32m [+] Your new dynamic IPv6 address: $current_ipv6"
                
                # change the duckdns ipv6 record
                curl -s "https://www.duckdns.org/update?domains=$user_domain&token=$token&ipv6=$current_ipv6&verbose=true"
                # write the result
                echo -e "\033[0;32m [+] Updated: The IPv6 is successfully set on DuckDNS with the value of: $current_ipv6."
                echo "$current_ipv6" > $IP_STORE_FILE
                exit 0
            else
                echo -e "\033[0;37m [~] No change: The current IPv6 address has not changed so on DuckDNS update needed."
                exit 0
            fi
