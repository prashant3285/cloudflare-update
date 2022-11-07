# cloudflare-update-ipv6-DNS-AAAA
Cloudflare DNS record update periodically - AAAA record for ipv6

more info on running and cron
https://github.com/fire1ce/DDNS-Cloudflare-Bash

Source
https://github.com/namnamir/configurations-and-security-hardening/blob/main/DDNS.md

script
check AAAA from cloudflare and change if needed

local script
this script checks change in ipv6 locally and if change is detected will update Cloudflare DNS
with local check, script interval can be reduces as cloudflare is only called in case of change and server downtime is reduced
