#!/bin/bash

# Set a variable here for the host name of the CRL web server
crlServer="crl1.epic.com"
network="TEST"  # or PROD for production

# Get ourselves into the correct directory to store the temp files
cd /var/tmp || exit

# Delete the old temporary files
if [ -f "care_everywhere_$network.crl" ]; then
        rm -f "care_everywhere_$network.crl"
        echo "Deleted old crl file"
fi

if [ -f "care_everywhere_$network.crl.pem" ]; then
        rm -f "care_everywhere_$network.crl.pem"
        echo "Deleted old pem file"
fi

# Check for the IP address of the hostname for the certificate web server
ip=$(host $crlServer | awk '/^[[:alnum:].-]+ has address/ { print $4 ; exit }')

# If we get a result from the host check above, continue to download the CRL from the certificate web server
if [ -n "$ip" ]; then
        curl -s -o "/var/tmp/care_everywhere_$network.crl" "http://$crlServer/Cert/CareEverywhere-$network-Policy-Issuing-CA.crl"
        echo "Downloaded new crl file"
fi

# If we successfully get the file from the server, we need to convert it to PEM format for the Big-IP
if [ -f "care_everywhere_$network.crl" ]; then
        openssl crl -in "care_everywhere_$network.crl" -out "care_everywhere_$network.crl.pem" -inform DER -outform PEM
        echo "Converted new crl file to pem file"

        declare -x REMOTEUSER="root"

        # Once the file is converted, we need to put it in the valid location for the Big-IP to access it
        tmsh create sys file ssl-crl "/Common/care_everywhere_$network.crl" source-path "file:///var/tmp/care_everywhere_$network.crl.pem"
        echo "Loaded pem file into ssl-crl"
fi