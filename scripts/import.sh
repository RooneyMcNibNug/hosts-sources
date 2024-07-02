#!/usr/bin/env bash

# The perpose of this script is to import various external hosts files into lists
# that only contains domain.tld, for easier working with the lists to our RPZ files

# Exit on any errors

set -e

# Set the right path for "executebles"
git_dir="$(git rev-parse --show-toplevel)"

WGET="$(command -v wget)"
# CURL="$(command -v curl)"
# PYTHON="$(command -v python3)"

c() {
    curl --tcp-fastopen \
        --tcp-nodelay \
        --tr-encoding \
        --compressed \
        --http2 \
        --ignore-content-length \
        --silent \
        --retry 5 \
        --retry-delay 2 "${1}"
}

cd "${git_dir}"

# Clean up old data dir to make a fresh a data dir as possible
rm -fr "${git_dir}/data/"

# Next let's Download some external sources, so we don't need to keep
# downloading them, and save them some bandwidth

mkdir -p "${git_dir}/data/yoyo.org/"
c 'https://pgl.yoyo.org/adservers/serverlist.php?hostformat=one-line&showintro=0&mimetype=plaintext' | grep -Ev '#' | tr , '\n' | sort -u >"data/yoyo.org/domain.list"
echo "Imported yoyo"

# Full featured RPZ list availble from
# https://sslbl.abuse.ch/blacklist/sslbl.rpz
mkdir -p "${git_dir}/data/abuse.ch/sslipblacklist/"
c "https://sslbl.abuse.ch/blacklist/sslipblacklist.txt" | tr -d '\015' | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sed 's/ \;.*$//' | awk -F "[/.]" '{  printf("32.%s.%s.%s.%s.rpz-ip\tCNAME\t.\n32.%s.%s.%s.%s.rpz-client-ip\tCNAME\trpz-drop.\n",$4,$3,$2,$1,$4,$3,$2,$1) }' >"data/abuse.ch/sslipblacklist/ipv4.in-addr.arpa"
c "https://sslbl.abuse.ch/blacklist/sslipblacklist.txt" | tr -d '\015' | grep -v "#" | cut -d " " -f 1 >"data/abuse.ch/sslipblacklist/ip4.list"
echo "Imported abuse.ch"

mkdir -p "${git_dir}/data/anudeepND/adservers/"
echo "anudeepND"
${WGET} -qO- "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt" | awk '/^(#|$)/{ next }; { if ( $2 ~ /[a-z]/ ) printf("%s\n",tolower($2)) | "sort -i | uniq -u -i " }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/anudeepND/adservers/domain.list"
echo "Imported anudeepND"

mkdir -p "${git_dir}/data/abuse.ch/urlhaus/"
${WGET} -qO- 'https://urlhaus.abuse.ch/downloads/rpz/' | awk '/^;/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' >"data/abuse.ch/urlhaus/domain.list"
echo "Imported urlhaus.abuse.ch"

mkdir -p "${git_dir}/data/someonewhocares/"
${WGET} -qO- 'http://someonewhocares.org/hosts/hosts' | grep -v '#' | awk '/^(#|$)/{ next }; { if ( $2 ~ /[a-z]/ ) printf("%s\n",tolower($2)) | "sort -i | uniq -u -i " }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/someonewhocares/domain.list"
printf "Imported someonewhocares\n"

mkdir -p "${git_dir}/data/fademind_add_risk/"
${WGET} -qO- "https://github.com/FadeMind/hosts.extras/raw/master/add.Risk/hosts" | awk '/^(#|$)/{ next }; { if ( $2 ~ /[a-z]/ ) printf("%s\n",tolower($2)) | "sort -i | uniq -u -i " }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/fademind_add_risk/domain.list"
echo "Imported FadeMind add.Risk"

mkdir -p "${git_dir}/data/fademind_add_spam/"
${WGET} -qO- "https://github.com/FadeMind/hosts.extras/raw/master/add.Spam/hosts" | awk '/^(#|$)/{ next }; { if ( $2 ~ /[a-z]/ ) printf("%s\n",tolower($2)) | "sort -i | uniq -u -i " }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/fademind_add_spam/domain.list"
echo "Imported FadeMind add.Spam"

mkdir -p "${git_dir}/data/fademind_antipopads/"
${WGET} -qO- "https://github.com/FadeMind/hosts.extras/raw/master/antipopads/hosts" | awk '/^(#|$)/{ next }; { if ( $2 ~ /[a-z]/ ) printf("%s\n",tolower($2)) | "sort -i | uniq -u -i " }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/fademind_antipopads/domain.list"
echo "Imported FadeMind AntiPopAds"

mkdir -p "${git_dir}/data/fademind_blocklists-facebook/"
${WGET} -qO- "https://github.com/FadeMind/hosts.extras/raw/master/blocklists-facebook/hosts" | awk '/^(#|$)/{ next }; { if ( $2 ~ /[a-z]/ ) printf("%s\n",tolower($2)) | "sort -i | uniq -u -i " }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/fademind_blocklists-facebook/domain.list"
echo "Imported FadeMind blocklists-facebook"

mkdir -p "${git_dir}/data/CoinBlockerLists/"
c 'https://zerodot1.gitlab.io/CoinBlockerLists/list.txt' | sort -u | uniq -u | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/CoinBlockerLists/domain.list"
echo "Imported CoinBlockerLists"

mkdir -p "${git_dir}/data/mvps/"
${WGET} -qO- "http://winhelp2002.mvps.org/hosts.txt" | awk '/^(#|$)/{ next }; { if ( $2 ~ /[a-z]/ ) printf("%s\n",tolower($2)) | "sort -i | uniq -u -i " }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/mvps/domain.list"
echo "Imported mvps"

wsbLists=(spy update extra)
wsbUrl="https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/data/hosts/"

for d in "${wsbLists[@]}"; do
    mkdir -p "${git_dir}/data/windowsspyblocker/${d}"
    echo -e "\tImporting ${d}"
    ${WGET} -qO- "${wsbUrl}/${d}.txt" | grep -vE '^(#|$)' | sed 's/^0.0.0.0\ //g' | sort -u >"data/windowsspyblocker/${d}.list"
done
${WGET} -qO "data/windowsspyblocker/LICENSE" "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/LICENSE"
${WGET} -qO "data/windowsspyblocker/README.md" "https://raw.githubusercontent.com/crazy-max/WindowsSpyBlocker/master/README.md"
unset wsbLists wsbUrl

echo "Imported WindowsSpyBlocker"

mkdir -p "${git_dir}/data/adaway/domain}"
${WGET} -qO- "https://raw.githubusercontent.com/AdAway/adaway.github.io/master/hosts.txt" | awk '/^(#|$)/{ next }; { if ( $2 ~ /[a-z]/ ) printf("%s\n",tolower($2)) | "sort -i | uniq -u -i " }' >"data/adaway/domain.list"
${WGET} -q "https://raw.githubusercontent.com/AdAway/adaway.github.io/master/README.md" -O "data/adaway/README.md"
${WGET} -q "https://raw.githubusercontent.com/AdAway/adaway.github.io/master/LICENSE.md" -O "data/adaway/LICENSE.md"
echo "Imported adaway.github.io"

mkdir -p "${git_dir}/data/dg-malicious/"
${WGET} -qO- "https://www.squidblacklist.org/downloads/dg-malicious.acl" | awk '/^(#|$)/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/dg-malicious/domain.list"
echo "Imported dg-malicious"

mkdir -p "${git_dir}/data/dg-ads/"
${WGET} -qO- "https://www.squidblacklist.org/downloads/dg-ads.acl" | awk '/^(#|$)/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/dg-ads/domain.list"
echo "Imported dg-ads"

mkdir -p "${git_dir}/data/malwaredomainlist/"
${WGET} -qO- "https://www.malwaredomainlist.com/hostslist/hosts.txt" | awk '/^(#|$)/{ next }; { if ( $2 ~ /[a-z]/ ) printf("%s\n",tolower($2)) | "sort -i | uniq -u -i " }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/malwaredomainlist/domain.list"
echo "Imported malwaredomainlist"

mkdir -p "${git_dir}/data/joewein/"
${WGET} -qO- "https://www.joewein.net/dl/bl/dom-bl-base.txt" | grep -Ev '\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b' | grep -Ev '(\%a\;419|\{|^$)' | sed 's/\;.*//' >"data/joewein/domain.list"
echo "Imported joewein"

mkdir -p "${git_dir}/data/suspiciousdomains_low/"
${WGET} -qO- "https://www.dshield.org/feeds/suspiciousdomains_Low.txt" | awk '/^(#|$)/{ next }; /^Site/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/suspiciousdomains_low/domain.list"
echo "Imported suspiciousdomains Low"

mkdir -p "${git_dir}/data/suspiciousdomains_medium/"
${WGET} -qO- "https://www.dshield.org/feeds/suspiciousdomains_Medium.txt" | awk '/^(#|$)/{ next }; /^Site/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/suspiciousdomains_medium/domain.list"
echo "Imported suspiciousdomains Medium"

mkdir -p "${git_dir}/data/suspiciousdomains_high/"
${WGET} -qO- "https://www.dshield.org/feeds/suspiciousdomains_High.txt" | awk '/^(#|$)/{ next }; /^Site/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/suspiciousdomains_high/domain.list"
echo "Imported suspiciousdomains High"

mkdir -p "${git_dir}/data/notrack/blocklists/"
c "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-blocklist.txt" | awk '/^(#|$)/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/notrack/blocklists/domain.list"
echo "Imported notrack-blocklist"

mkdir -p "${git_dir}/data/notrack/malware/"
c "https://gitlab.com/quidsup/notrack-blocklists/raw/master/notrack-malware.txt" | awk '/^(#|$)/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/notrack/malware/domain.list"
echo "Imported notrack-malware"

# https://bitbucket.org/expiredsources/hosts-file.net/src/master/
echo "Downloading Active hosts-file.net...."

hpLists=(ad_servers emd exp fsa grm hjk mmt psh pup)
hpUrl="https://bitbucket.org/expiredsources/hosts-file.net/raw/master/active/"

for d in "${hpLists[@]}"; do
    mkdir -p "${git_dir}/data/hphosts/${d}"
    echo -e "\tImporting ${d}"
    touch "data/hphosts/${d}/domain.list"
    ${WGET} -qO- "${hpUrl}/${d}.txt" | grep -vE '^(#|$)' >"data/hphosts/${d}/domain.list"
done

# For protecting the future devs we unset variables
hpUrl=""

echo "Puuh.. done importing Active hosts-file.net...."

mkdir -p "${git_dir}/data/cedia/"
${WGET} -qO- https://mirror.cedia.org.ec/malwaredomains/immortal_domains.txt | awk '/^(#|$)/{ next }; /^Site/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' >"data/cedia/domain.list"
echo "Imported cedia"

mkdir -p "${git_dir}/data/malwaredomains/"
${WGET} -qO- https://mirror1.malwaredomains.com/files/justdomains | grep -ivE '^(#|$)' | sort | uniq -u >data/malwaredomains/domain.list
echo "Imported mirror1.malwaredomains.com"

# blocklistproject CNAME blocklist-site
# This url is bullshit, trying to bump his own domain. Bullshit url="bsUrl="https://blocklist.site/app/dl/""
bsLists=(abuse ads crypto drugs facebook fraud gambling malware phishing piracy porn ransomware redirect scam torrent tracking)
bsUrl="https://raw.githubusercontent.com/blocklistproject/Lists/master/alt-version/"

echo "Importing blocklistproject"
for bs in "${bsLists[@]}"; do
    mkdir -p "${git_dir}/data/blocklist_${bs}"
    echo -e "\t- ${bs}"
    c "${bsUrl}${bs}-nl.txt" | awk '/^(#|$)/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",tolower($1)) }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' | sort | uniq -u >"data/blocklist_${bs}/domain.list"
done

# Unset variables
bsUrl=""

echo "Imported blocklist.site"

mkdir -p "${git_dir}/data/BBcan177_MS-4/" "${git_dir}/data/BBcan177_MS-2/"
c "https://gist.githubusercontent.com/BBcan177/b6df57cef74e28d90acf1eec93d62d3b/raw/f0996cf5248657ada2adb396f3636be8716b99eb/MS-4" | awk '/^(#|$)/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/BBcan177_MS-4/domain.list"
c "https://gist.githubusercontent.com/BBcan177/4a8bf37c131be4803cb2/raw/343ff780e15205b4dd0de37c86af34cfb26b2fbe/MS-2" | awk '/^(#|$)/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/BBcan177_MS-2/domain.list"
echo "Imported BBcan177"

mkdir -p "${git_dir}/data/phishing_army_blocklist_extended/"
${WGET} -qO- "https://phishing.army/download/phishing_army_blocklist_extended.txt" | awk '/^(#|$)/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/phishing_army_blocklist_extended/domain.list"
echo "Imported phishing.army"

# spamhaus.org
# drop
mkdir -p "${git_dir}/data/spamhaus/drop/"
${WGET} -qO- "https://www.spamhaus.org/drop/drop.txt" | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sed 's/ \;.*$//' | awk -F "[/.]" '{  printf("%s.%s.%s.%s.%s.rpz-ip\tCNAME\t.\n%s.%s.%s.%s.%s.rpz-client-ip\tCNAME\trpz-drop.\n",$5,$4,$3,$2,$1,$5,$4,$3,$2,$1) }' >"data/spamhaus/drop/ipv4.in-addr.arpa"
echo "Imported Drop spamhaus.org"

# implanting .dtq from https://www.mypdns.org/w/ixfrdist/#532

# Edrop
mkdir -p "${git_dir}/data/spamhaus/edrop/"
${WGET} -qO- "https://www.spamhaus.org/drop/edrop.txt" | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | sed 's/ \;.*$//' | awk -F "[/.]" '{  printf("%s.%s.%s.%s.%s.rpz-ip\tCNAME\t.\n%s.%s.%s.%s.%s.rpz-client-ip\tCNAME\trpz-drop.\n",$5,$4,$3,$2,$1,$5,$4,$3,$2,$1) }' >"data/spamhaus/edrop/ipv4.in-addr.arpa"
echo "Imported eDrop spamhaus.org"

# coinblocker
mkdir -p "${git_dir}/data/spamhaustech/coinblocker/"
drill axfr coinblocker.srv @35.156.219.71 -p 53 | grep -vE "^(;|$)|(SOA|NS)" | sed -e 's/\.coinblocker\.srv\.[[:blank:]].*$//g' >"data/spamhaustech/coinblocker/domain.list"
echo "Imported coinblocker .dtq"

# Disconnect ad-servers
mkdir -p "${git_dir}/data/disconnect-me/"
c "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt" | awk '/^(#|$)/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' >"data/disconnect-me/domain.list"
echo "Imported simple disconnect.me"

# We need to avoid the IP hosts provided by openfish as they can't be used with hosts files'
mkdir -p "${git_dir}/data/openfish/"
c "https://openphish.com/feed.txt" | awk -F "/" '!/^($|#)/{ print $3 | "sort -u | uniq -u -i " }' | grep -Ev "\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b" >"data/openfish/domain.list"
c "https://openphish.com/feed.txt" | awk -F "/" '!/^($|#)/{ print $3 | "sort -u | uniq -u -i " }' | grep -E "\b(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b" | awk -F "." '{  printf("32.%s.%s.%s.%s.rpz-ip\tCNAME\t.\n32.%s.%s.%s.%s.rpz-client-ip\tCNAME\trpz-drop.\n",$4,$3,$2,$1,$4,$3,$2,$1) }' >"data/openfish/ipv4.in-addr.arpa"
echo "Imported openfish.com"

# START @mitchellkrogza's many lists
echo "START importing @mitchellkrogza's many lists"

mkdir -p "${git_dir}/data/mitchellkrogza/badd_boyz_hosts/"
echo ""
echo "Badd-Boyz-Hosts"
echo ""
${WGET} -qO- "https://raw.githubusercontent.com/mitchellkrogza/Badd-Boyz-Hosts/master/hosts" | awk '/^(#|$)/{ next }; { if ( $2 ~ /[a-z]/ ) printf("%s\n",tolower($2)) | "sort -i | uniq -u -i " }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/mitchellkrogza/badd_boyz_hosts/domain.list"
${WGET} -q "https://raw.githubusercontent.com/mitchellkrogza/Badd-Boyz-Hosts/master/README.md" -O "data/mitchellkrogza/badd_boyz_hosts/README.md"
${WGET} -q "https://raw.githubusercontent.com/mitchellkrogza/Badd-Boyz-Hosts/master/LICENSE.md" -O "data/mitchellkrogza/badd_boyz_hosts/LICENSE.md"

mkdir -p "${git_dir}/data/mitchellkrogza/the-big-list-of-hacked-malware-web-sites/"
echo ""
echo "The-Big-List-of-Hacked-Malware-Web-Sites"
echo ""
${WGET} -qO- "https://raw.githubusercontent.com/mitchellkrogza/The-Big-List-of-Hacked-Malware-Web-Sites/master/hacked-domains.list" | awk '/^(#|$)/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/mitchellkrogza/the-big-list-of-hacked-malware-web-sites/domain.list"
${WGET} -q "https://raw.githubusercontent.com/mitchellkrogza/The-Big-List-of-Hacked-Malware-Web-Sites/master/README.md" -O "data/mitchellkrogza/the-big-list-of-hacked-malware-web-sites/README.md"
${WGET} -q "https://raw.githubusercontent.com/mitchellkrogza/The-Big-List-of-Hacked-Malware-Web-Sites/master/LICENSE.md" -O "data/mitchellkrogza/the-big-list-of-hacked-malware-web-sites/LICENSE.md"

mkdir -p "${git_dir}/data/mitchellkrogza/phishing.database/"
echo ""
echo "Phishing.Database"
echo ""
${WGET} -qO- "https://raw.githubusercontent.com/mitchellkrogza/Phishing.Database/master/phishing-domains-ACTIVE.txt" | awk '/^(#|$)/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"data/mitchellkrogza/phishing.database/domain.list"
${WGET} -qO- "https://raw.githubusercontent.com/mitchellkrogza/Phishing.Database/master/phishing-IPs-ACTIVE.txt" | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}" | awk -F "." '{  printf("32.%s.%s.%s.%s.rpz-ip\tCNAME\t.\n32.%s.%s.%s.%s.rpz-client-ip\tCNAME\trpz-drop.\n",$4,$3,$2,$1,$4,$3,$2,$1) }' >"data/mitchellkrogza/phishing.database/ipv4.in-addr.arpa"
${WGET} -qO- "https://raw.githubusercontent.com/mitchellkrogza/Phishing.Database/master/phishing-IPs-ACTIVE.txt" | grep -E "([0-9]{1,3}[\.]){3}[0-9]{1,3}" >"data/mitchellkrogza/phishing.database/ipv4.list"
${WGET} -q "https://raw.githubusercontent.com/mitchellkrogza/Phishing.Database/master/LICENSE.md" -O "data/mitchellkrogza/phishing.database/LICENSE.md"
${WGET} -q "https://raw.githubusercontent.com/mitchellkrogza/Phishing.Database/master/README.md" -O "data/mitchellkrogza/phishing.database/README.md"

# As I have no idea or couln't find any RFC telling me that an IPv4 is a valid
# domain name. It is nessesary to remove them from "Domain"? list :smirk: :devil:

mkdir -p "${git_dir}/data/mitchellkrogza/Ultimate.Hosts.Blacklist/"
echo ""
echo "Ultimate.Hosts.Blacklist"
echo ""
${WGET} -qO- "https://raw.githubusercontent.com/Ultimate-Hosts-Blacklist/Ultimate.Hosts.Blacklist/master/domains/domains0.list" | grep -vE "^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$" >"data/mitchellkrogza/Ultimate.Hosts.Blacklist/domain.list"
${WGET} -q "https://raw.githubusercontent.com/mitchellkrogza/Ultimate.Hosts.Blacklist/master/README.md" -O "data/mitchellkrogza/Ultimate.Hosts.Blacklist/README.md"
${WGET} -q "https://raw.githubusercontent.com/mitchellkrogza/Ultimate.Hosts.Blacklist/master/LICENSE.md" -O "data/mitchellkrogza/Ultimate.Hosts.Blacklist/LICENSE.md"
echo "Done importing @mitchellkrogza's many lists"
# mitchellkrogza many lists

echo ""
echo "Importing 1Hosts"
echo ""
mkdir -p "${git_dir}/data/1Hosts"
${WGET} -qO- "https://raw.githubusercontent.com/badmojr/1Hosts/master/Xtra/domains.txt" | awk '/^(#|$)/{ next }; /^Site/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",$1) | "sort -u -i" }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' >"${git_dir}/data/domain.list"

muLists=(malware ads-tracking ads-tracking-breaking)
muUrl="https://raw.githubusercontent.com/migueldemoura/ublock-umatrix-rulesets/master/Hosts/"

for mu in "${muLists[@]}"; do
    mkdir -p "${git_dir}/data/migueldemoura_${mu}"
    echo "Importing ${mu}"
    c "${muUrl}${mu}" | awk '/^(#|$)/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",tolower($1)) }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' | sort | uniq -u >"data/migueldemoura_${mu}/domain.list"
done

# Unset variables
muUrl=""

# @ShadowWhisperer

echo "Let's import @ShadowWhisperer"

SWLists=(Ads Apple Bloat Chat Cryptocurrency Dating Dynamic Filter Free Junk Malware Marketing Marketing-Email Microsoft Remote Risk Scam Shock Tracking Tunnels Typo UrlShortener)
SWUrl="https://raw.githubusercontent.com/ShadowWhisperer/BlockLists/master"

for SW in "${SWLists[@]}"; do
    mkdir -p "${git_dir}/data/shadowwhisperer/${SW}"
    echo "Importing @ShadowWhisperer ${SW}"
    c "${SWUrl}/Lists/${SW}" | awk '/^(#|$)/{ next }; { if ( $1 ~ /[a-z]/ ) printf("%s\n",tolower($1)) }' | perl -lpe 's/^\s*(.*\S)\s*$/$1/' | sort | uniq -u >"$git_dir/data/shadowwhisperer/${SW}/domain.list"
done

echo "Import LICENSE"
${WGET} "${SWUrl}/LICENSE" -O "$git_dir/data/shadowwhisperer/LICENSE"

echo "Import README"

${WGET} "${SWUrl}/README.md" -O "$git_dir/data/shadowwhisperer/README.md"

# Unset variables
SWUrl=""

echo "Done with @ShadowWhisperer, thanks for your contribution, may the the ods"
echo "always be in your favour :smirk:"

echo ""
echo ""
echo "The script ${0}"
echo "Exited with error code ${?}\n\n"

# git add .

# tag=$(date +'day: %j of year %Y %H:%M:%S')

# git commit -a -m "New release ${tag}" && git push
