#!/bin/bash
# Update the pihole lists
# - adlists.list (https://v.firebog.net/hosts/lists.php?type=tick)
# - whitelist.txt (https://github.com/anudeepND/whitelist)
# - blacklisting youtube ads (https://github.com/kboghdady/youTube_ads_4_pi-hole)

piholeIP=`hostname -I |awk '{print $1}'`

adlistsList="/etc/pihole/adlists.list"
blackList="/etc/pihole/black.list"
blacklistTxt="/etc/pihole/blacklist.txt"
whitelistTxt="/etc/pihole/whitelist.txt"

# set adlists.list to default and adding firebog's list
echo 'https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
https://mirror1.malwaredomains.com/files/justdomains
http://sysctl.org/cameleon/hosts
https://zeustracker.abuse.ch/blocklist.php?download=domainblocklist
https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt
https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt
https://hosts-file.net/ad_servers.txt' > $adlistsList
curl -sS 'https://v.firebog.net/hosts/lists.php?type=tick' | sudo tee -a $adlistsList

# get whitelist updates
curl -sS 'https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/whitelist.txt' | sudo tee -a $whitelistTxt
curl -sS 'https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/referral-sites.txt' | sudo tee -a $whitelistTxt
curl -sS 'https://raw.githubusercontent.com/anudeepND/whitelist/master/domains/optional-list.txt' | sed "/#/d" | sed "/^$/d" | sed "/./!d" | sudo tee -a $whitelistTxt

# blacklisting youtube ad's
# Get the domain list from hackeragent api
# change it to be r[Number]---sn--
# adding to the blacklist
curl -sS 'https://api.hackertarget.com/hostsearch/?q=googlevideo.com' | awk -F, 'NR>1{print $1}'| sed "s/\(^r[[:digit:]]*\)\.\(sn\)/$piholeIP \1---\2-/ " | sudo tee -a $blackList
curl -sS 'https://api.hackertarget.com/hostsearch/?q=googlevideo.com' | awk -F, 'NR>1{print $1}'| sed "s/\(^r[[:digit:]]*\)\.\(sn\)/\1---\2-/ " | sudo tee -a $blacklistTxt

# collecting the youtube ads website from the pihole logs and added it the youtubeList.txt
sudo cat /var/log/pihole*.log | grep 'r[0-9]*-.*.googlevideo'| awk -v a=$piholeIP '{print a " " $8}'| sort | uniq | sudo tee -a $blackList
sudo cat /var/log/pihole*.log | grep 'r[0-9]*-.*.googlevideo'| awk '{print $8}'| sort | uniq | sudo tee -a $blacklistTxt

sudo sed -i "/redirector.googlevideo.com/d" $blackList
sudo sed -i "/manifest.googlevideo.com/d" $blackList
sudo sed -i "/redirector.googlevideo.com/d" $blacklistTxt
sudo sed -i "/manifest.googlevideo.com/d" $blacklistTxt

# check to see if gawk is installed. if not it will install it
dpkg -l | grep -qw gawk || sudo apt-get install gawk
wait


# remove the duplicate records in place
gawk -i inplace '!a[$0]++' $adlistsList
wait
gawk -i inplace '!a[$0]++' $whitelistTxt
wait
gawk -i inplace '!a[$0]++' $blackList
wait
gawk -i inplace '!a[$0]++' $blacklistTxt
wait

# update gravity
pihole -g >/dev/null