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
## mac id based IPv6 suffix for your server e.g. dynamic part (prefix) 0000:0000:0000:0000 fixed part based on device mac (suffix) :0000:0000:0000:0000
ipv6_suffix='add here without quote mark fixed part of ipv6' 

# Check if the script is already running
# if [ ps ax | grep $0 | grep -v $$ | grep bash | grep -v grep ]; then
#     echo -e "\033[0;31m [-] The script is already running."
#     exit 1
# fi

###  Create .update-cloudflare-dns.log file of the last run for debug
parent_path="$(dirname "${BASH_SOURCE[0]}")"
FILE=${parent_path}/update-cloudflare-dns.log
if ! [ -x "$FILE" ]; then
  touch "$FILE"
fi

LOG_FILE=${parent_path}'/update-cloudflare-dns.log'

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

# get the basic data
#ipv4=$(curl -s -X GET -4 https://ifconfig.co)
ipv6=$(curl -s -X GET -6 https://ifconfig.co)
user_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/user/tokens/verify" \
               -H "Authorization: Bearer $api_token" \
               -H "Content-Type:application/json" \
          | jq -r '{"result"}[] | .id'
         )

# write down IPv4 and/or IPv6
#if [ $ipv4 ]; then echo -e "\033[0;32m [+] Your public IPv4 address: $ipv4"; else echo -e "\033[0;33m [!] Unable to get any public IPv4 address."; fi
if [ $ipv6 ]; then echo -e "\033[0;32m [+] Your public IPv6 address: $ipv6"; else echo -e "\033[0;33m [!] Unable to get any public IPv6 address."; fi

# check if the user API is valid and the email is correct
if [ $user_id ]; then
    zone_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$zone_name&status=active" \
                   -H "Content-Type: application/json" \
                   -H "X-Auth-Email: $email" \
                   -H "Authorization: Bearer $api_token" \
              | jq -r '{"result"}[] | .[0] | .id'
             )
    # check if the zone ID is avilable
    if [ $zone_id ]; then
        # check if there is any IP version 4
        # if [ $ipv4 ]; then
        #     # Check if A Record exists
        #     if [ -z "${check_record_ipv4}" ]; then
        #         echo -e "\033[0;31m [-] No A Record is set for ${dns_record}. This should be created first!"
        #         exit 1
        #     fi
        #     dns_record_a_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$dns_record"  \
        #                            -H "Content-Type: application/json" \
        #                            -H "X-Auth-Email: $email" \
        #                            -H "Authorization: Bearer $api_token"
        #                      )
        #     dns_record_a_ip=$(echo $dns_record_a_id |  jq -r '{"result"}[] | .[0] | .content')
        #     # if a new IPv4 exist; current IPv4 is different with the actual IPv4
        #     if [ $dns_record_a_ip != $ipv4 ]; then
        #         # change the A record
        #         curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $dns_record_a_id | jq -r '{"result"}[] | .[0] | .id')" \
        #              -H "Content-Type: application/json" \
        #              -H "X-Auth-Email: $email" \
        #              -H "Authorization: Bearer $api_token" \
        #              --data "{\"type\":\"A\",\"name\":\"$dns_record\",\"content\":\"$ipv4\",\"ttl\":1,\"proxied\":false}" \
        #         | jq -r '.errors'
        #         # write the result
        #         echo -e "\033[0;32m [+] Updated: The IPv4 is successfully set on Cloudflare as the A Record with the value of: $ipv4."
        #         exit 0
        #     else
        #         echo -e "\033[0;37m [~] No change: The current IPv4 address matches Cloudflare."
        #         exit 0
        #     fi
        # fi

        # check if there is any IP version 6
        if [ $ipv6 ]
        then
            # Check A Record exists
            if [ -z "${check_record_ipv6}" ]; then
                echo -e "\033[0;31m [-] No AAAA Record called ${dns_record}. This must be created first!"
                exit 1
            fi
            dns_record_aaaa_id=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=AAAA&name=$dns_record"  \
                                      -H "Content-Type: application/json" \
                                      -H "X-Auth-Email: $email" \
                                      -H "Authorization: Bearer $api_token"
                                )
            dns_record_aaaa_ip=$(echo $dns_record_aaaa_id | jq -r '{"result"}[] | .[0] | .content')
            # if a new IPv6 exist; current IPv6 is different with the actual IPv6
            dns_prefix=$(echo $dns_record_aaaa_ip | cut -d ':' -f1-4)
            ipv6_prefix=$(echo $ipv6 | cut -d ':' -f1-4)
            if [ $dns_prefix != $ipv6_prefix ]; then
                new_ipv6=$(echo ${ipv6_prefix}${ipv6_suffix})
                echo -e "\033[0;32m [+] Your static IPv6 address: $new_ipv6"
                # change the AAAA record
                curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$(echo $dns_record_aaaa_id | jq -r '{"result"}[] | .[0] | .id')" \
                     -H "Content-Type: application/json" \
                     -H "X-Auth-Email: $email" \
                     -H "Authorization: Bearer $api_token" \
                     --data "{\"type\":\"AAAA\",\"name\":\"$dns_record\",\"content\":\"$new_ipv6\",\"ttl\":1,\"proxied\":true}" \
                | jq -r '.errors'
                # write the result
                echo -e "\033[0;32m [+] Updated: The IPv6 is successfully set on Cloudflare as the AAAA Record with the value of: $new_ipv6."
                exit 0
            else
                echo -e "\033[0;37m [~] No change: The current IPv6 address matches the existing records on Cloudflare."
                exit 0
            fi
        fi
    else
        echo -e "\033[0;31m [-] There is a problem with getting the Zone ID (sub-domain) or the email address (username). Check them and try again."
        exit 1
    fi
else
    echo -e "\033[0;31m [-] There is a problem with either the API token. Check it and try again."
    exit 1
fi
