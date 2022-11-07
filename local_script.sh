#!/bin/bash
# based on https://gist.github.com/Tras2/cba88201b17d765ec065ccbedfb16d9a
# initial data; they need to be filled by the user
## API token; e.g. FErsdfklw3er59dUlDce44-3D43dsfs3sddsFoD3
api_token='add here without quote mark'
## the email address associated with the Cloudflare account; e.g. email@gmail.com
email='add here without quote mark'
## the zone (domain) should be modified; e.g. example.com
zone_name='add here without quote mark'
## the dns record (sub-domain) that needs to be modified; e.g. sub.example.com
dns_record='add here without quote mark'

# Check if the script is already running
# if [ ps ax | grep $0 | grep -v $$ | grep bash | grep -v grep ]; then
#     echo -e "\033[0;31m [-] The script is already running."
#     exit 1
# fi

###  Create .update-cloudflare-dns.log file of the last run for debug
parent_path="$(dirname "${BASH_SOURCE[0]}")"
FILE=${parent_path}/cloudflare_local.log
if ! [ -x "$FILE" ]; then
  touch "$FILE"
fi

STOREFILE=${parent_path}/ipstore.txt
if ! [ -x "$STOREFILE" ]; then
  touch "$STOREFILE"
fi

LOG_FILE=${parent_path}'/cloudflare_local.log'
IP_STORE_FILE=${parent_path}'/ipstore.txt'

### Write last run of STDOUT & STDERR as log file and prints to screen
exec > >(tee $LOG_FILE) 2>&1
echo "==> $(date "+%Y-%m-%d %H:%M:%S")"

# Check if jq is installed
check_jq=$(which jq)
if [ -z "${check_jq}" ]; then
    echo -e "\033[0;31m [-] jq is not installed. Install it by 'sudo apt install jq'."
    exit 1
fi

# check the subdomain
# unnecessary if user values are added correctly
# check if the dns_record field (subdomain) contains dot
if [[ $dns_record == *.* ]]; then
    # if the zone_name field (domain) is not in the dns_record
    if [[ $dns_record != *.$zone_name ]]; then
        echo -e "\033[0;31m [-] The Zone in DNS Record does not match the defined Zone; check it and try again."
        exit 1
    fi
# if the dns_record (subdomain) is not complete and contains invalid characters
elif ! [[ $dns_record =~ [\w\d\-]+ ]]; then
    echo -e "\033[0;31m [-] The DNS Record contains illegal charecters, i.e., @, %, *, _, etc.; fix it and run the script again."
    exit 1
# if the dns_record (subdomain) is not complete, complete it
else
    dns_record="$dns_record.$zone_name"
fi

# Check if DNS Records Exists
#check_record_ipv4=$(dig -t a +short ${dns_record} | tail -n1)
check_record_ipv6=$(dig -t aaaa +short ${dns_record} | tail -n1)

# Check if our domain has ipv6 assgned, if not then eitehr AAAA record not exist or Network interface has not provided global ipv6
if [ -z "${check_record_ipv6}" ]; then
    echo -e "\033[0;31m [-] global ipv6 is not assigned, check if AAAA record exist on Clouflare or to restart network services and Server (Android) should be screen on mode"
    exit 1
fi

# This is all local operation - so old ipv6 is stored and compared to existing ipv6 - if IPS has  changed ipv6 then we trigger cloudflare change operation
old_ipv6=$(cat $IP_STORE_FILE)

# Getting current ipv6 from Network Interface (unique global ipv6) 
current_ipv6=$(ip -6 addr show dev wlan0 scope global dynamic mngtmpaddr | sed -e's/^.*inet6 \([^ ]*\)\/.*$/\1/;t;d')

if [ -z "${old_ipv6}" ]; then
    echo "$current_ipv6" > $IP_STORE_FILE
    echo -e "\033[0;37m [~] Script probably run for first time so no old record exist, Updating record and Skipping update of IP in Cloudflare DNS"
    exit 1
fi

if [ $old_ipv6 != $current_ipv6 ]; then
                
                echo -e "\033[0;32m [+] Your new static IPv6 address: $current_ipv6"
                
                zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name&status=active" \
                   -H "Content-Type: application/json" \
                   -H "X-Auth-Email: $email" \
                   -H "Authorization: Bearer $api_token" \
              | jq -r '{"result"}[] | .[0] | .id'
                    )

                dns_record_aaaa_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=AAAA&name=$dns_record"  \
                                      -H "Content-Type: application/json" \
                                      -H "X-Auth-Email: $email" \
                                      -H "Authorization: Bearer $api_token"
                                )

                # change the AAAA record
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $dns_record_aaaa_id | jq -r '{"result"}[] | .[0] | .id')" \
                     -H "Content-Type: application/json" \
                     -H "X-Auth-Email: $email" \
                     -H "Authorization: Bearer $api_token" \
                     --data "{\"type\":\"AAAA\",\"name\":\"$dns_record\",\"content\":\"$current_ipv6\",\"ttl\":1,\"proxied\":true}" \
                | jq -r '.errors'
                # write the result
                echo -e "\033[0;32m [+] Updated: The IPv6 is successfully set on Cloudflare as the AAAA Record with the value of: $current_ipv6."
                echo "$current_ipv6" > $IP_STORE_FILE
                exit 0
            else
                echo -e "\033[0;37m [~] No change: The current IPv6 address has not changed so on Cloudflare update needed."
                exit 0
            fi
