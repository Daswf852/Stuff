#!/bin/bash

declare -A addrLookup=( ["0x1234"]="foo" ["0x5678"]="bar")

#regexes:
#remove /^[A-Za-z0-9\-\._]* / to get addresses
#remove / 0x[0-9A-F]*$/ to get labels

file="$1"
while read -r line; do
	address=`echo $line | sed "s/^[A-Za-z0-9\-\._]* //"`
	label=`echo $line | sed "s/ 0x[0-9A-F]*$//"`
	#printf "label \"%s\" at address %s\n" $label $address
	addrLookup["$address"]="$label"
done < "$file"

while : ; do

	read -ep "Enter address: " addr
	if [ "${addrLookup[${addr}]}" != "" ]; then
		echo "${addrLookup[${addr}]}"
	elif [ "$addr" == "exit" ]; then
		echo "exiting"
		break
	else
		echo $addr
	fi

done