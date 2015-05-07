#!/bin/bash

function check_exists {
	which $1 &> /dev/null
}

function download {
	local URL=$1
	local FILE

	FILE=`basename $1`
	
	if check_exists wget; then
		wget -O "$FILE" "$URL"
	elif check_exists curl; then
		curl "$URL" -o "$FILE"
	else
		echo "Please install either wget or curl" >&2
		exit 1
	fi

	echo -n "$FILE"
}

PRINTER_CONF='printers.conf'
if [ ! -f "$PRINTER_CONF" ]; then
	PRINTER_CONF="$(mktemp -t ninja-unix_XXXXXX_printer.conf)"
	URL=https://raw.github.com/adicu/ninja-unix/master/printers.conf
	echo "No printers.conf. Attempting to download."
	mv "$(download "$URL")" "$PRINTER_CONF" >/dev/null
fi

LPADMIN=`which lpadmin`
if [ -z $LPADMIN ]; then
	echo "Could not find the lpadmin program." >&2
	echo "Either you have not installed CUPS, or lpadmin is not on your PATH" >&2
	exit 2
fi

add_ninja(){
	$LPADMIN -p $1 -E -v lpd://$2/public -m drv:///sample.drv/generic.ppd -L $3
}

read_config(){
	while read name address location
	do
		echo "Adding $name"
		add_ninja $name $uni@$address $location
	done
}

echo "What is your UNI?"
read uni

if [ -z $1 ]; then
	read_config < "$PRINTER_CONF"
else
	exists=`grep $1 "$PRINTER_CONF" | head -n 1`
	if [ -z "$exists" ]; then
		echo "Could not find printer matching this pattern" >&2
		exit 3
	fi
	grep $1 "$PRINTER_CONF" | read_config
fi
