#!/bin/bash
# [C] Odin

alias pc='proxychains'
which proxychains &> /dev/null || {
	echo "You need to install proxychains..."
	echo "run: sudo apt-get install proxychains -y"
	exit 1
}


declare -A REGEXS
URLS=()

ARCHIVE_DIR=/opt/pastebin
HASH_FILE=$ARCHIVE_DIR/.hash
LOG_FILE=$ARCHIVE_DIR/result.log
COOKIE_FILE=$ARCHIVE_DIR/.cookie

REGEXS["aws_client_id"]='(A3T[A-Z0-9]|AKIA|AGPA|AIDA|AROA|AIPA|ANPA|ANVA|ASIA)[A-Z0-9]{16}'
REGEXS["fb_access_token"]='EAACEdEose0cBA[0-9A-Za-z]+'
REGEXS["google_api_key"]='AIza[0-9A-Za-z\\-_]{35}'
REGEXS["heroky_api_key"]='[h|H][e|E][r|R][o|O][k|K][u|U].{0,30}[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}'
REGEXS["mailchamp_api_key"]='[0-9a-f]{32}-us[0-9]{1,2}'
REGEXS["mailgun_api_key"]='key-[0-9a-zA-Z]{32}'
REGEXS["slack_token"]='xox[baprs]-([0-9a-zA-Z]{10,48})?'
REGEXS["slack_webhook"]='https://hooks.slack.com/services/T[a-zA-Z0-9_]{8}/B[a-zA-Z0-9_]{8}/[a-zA-Z0-9_]{24}'
REGEXS["stripe_api_key"]='(?:r|s)k_live_[0-9a-zA-Z]{24}'
REGEXS["twitter_access_token"]='[1-9][ 0-9]+-(0-9a-zA-Z]{40}'
REGEXS["instagram_oauth"]='[0-9a-fA-F]{7}.[0-9a-fA-F]{32}'
REGEXS["github_oauth"]='[0-9a-fA-F]{40}'

[ ! -d $ARCHIVE_DIR ] && mkdir -p $ARCHIVE_DIR


function now {
	date +%D\ %T
}

function print {
	echo "[$(now)] $@" | tee -a $LOG_FILE
}

function http {
	pc curl -s \
		-H 'authority: pastebin.com' \
		-H 'cache-control: max-age=0' \
		-H 'referer: https://pastebin.com/' \
		-A 'Googlebot' "$@"
}

if [ ! -f $COOKIE_FILE ]; then
	echo "INFO: cookie not found. getting it"
	http -I 'https://pastebin.com/archive' \
		-c $COOKIE_FILE \
		-o /dev/null
fi


echo "INFO: Downloading data..."


while read url; do
	URLS+=("$url")
done <<< $(
	http -b $COOKIE_FILE 'https://pastebin.com/archive' \
		| grep 'class="status -public"></span><a href="' \
		| sed 's/.*href="/https:\/\/pastebin.com\/raw/g' \
		| sed 's/">.*//g'
)

NEW_HASH=$(printf "%s\n" "${URLS[@]}" | md5sum | awk '{print $1}')
if [ -f $HASH_FILE ]; then
	OLD_HASH=$(cat < $HASH_FILE)
	if [[ $OLD_HASH == $NEW_HASH ]]; then
		print "INFO: no difference."
    		exit 0
	fi
fi

echo "WARNING: something changed"
echo $NEW_HASH > $HASH_FILE

echo

# total 50 pages. https://pastebin.com/archive. Run 2 threads
for ((i=0;i<50;)); do
 	for x in {1..25}; do
		(
			url=${URLS[$i]}
			echo "CURRENT: $url"
			id=$!
			http "$url" > /tmp/file${id}.html

			for rule in "${!REGEXS[@]}"; do
				regex=${REGEXS[$rule]}

				grep -q "$regex" /tmp/file${id}.html

				if [ $? -eq 0 ]; then
					print "SUCCESS: $rule matched with \"$regex\" for $url"
					echo -en "\a"	# alert
					wget -U "Googlebot" "$url" \
						-O $ARCHIVE_DIR/"${rule}_${url##*/}" \
						-o /dev/null
				fi
			done
		) &
		let i++
	done
	wait
done
rm /tmp/file*

exit 0
