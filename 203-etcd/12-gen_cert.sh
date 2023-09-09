#!/bin/bash

# Generate a new private/public key pair and a certificate for a server.
#
# ***** This script assume the following: *****
#     Certificate filename: <name>.crt
#     CSR filename:         <name>.csr
#     Private key filename: <name>.key
#
# This is a bit dirty, but helps when you want to generate lots of certificate
# for testing. Was made to work in conjunction with:
# https://gist.github.com/ddella/c2bc100a091bc59f51b740a4f3663b75
#
# HOWTO use it: ./gen_cert.sh server1 intermediate-ca
#
# This will generate the following files:
#  -rw-r--r--   1 username  staff  1216 01 Jan 00:00 server.crt >> certificate
#  -rw-r--r--   1 username  staff   976 01 Jan 00:00 server.csr >> CSR
#  -rw-------   1 username  staff   302 01 Jan 00:00 server.key >> key pair
#
# Works with 'bash' and 'zsh' shell on macOS and Linux. Make sure you have OpenSSL *** in your PATH ***.
#
# *WARNING*
# This script was made for educational purposes ONLY.
# USE AT YOUR OWN RISK!"
DOMAIN='isociel.com'
EXTRA_SAN=''

if [[ $# -lt 3 || $# -gt 3 ]]
then
   printf "\nUsage: $0 <FQDN> <IP address> <name of CA or intermediate-CA>\n"
   printf "Ex.: ./gen_cert.sh server1 172.31.11.10 ca\n\n"
   exit -1
fi

printf "\nMaking certificate: $1 ...\n"
openssl ecparam -name prime256v1 -genkey -out $1.key
# openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out $1.key

openssl req -new -sha256 -key $1.key -subj "/C=CA/ST=QC/L=Montreal/O=$1/OU=IT/CN=$1.$DOMAIN" \
-addext "subjectAltName = DNS:localhost,DNS:*.localhost,DNS:$1,DNS:$1.$DOMAIN,IP:127.0.0.1,IP:$2$EXTRA_SAN" \
-addext "basicConstraints = CA:FALSE" \
-addext "extendedKeyUsage = clientAuth,serverAuth" \
-addext "subjectKeyIdentifier = hash" \
-addext "keyUsage = nonRepudiation, digitalSignature, keyEncipherment, keyAgreement, dataEncipherment" \
-addext "authorityInfoAccess = caIssuers;URI:http://localhost:8000/Intermediate-CA.cer,OCSP;URI:http://localhost:8000/ocsp" \
-addext "crlDistributionPoints = URI:http://localhost:8000/crl/Root-CA.crl,URI:http://localhost:8080/crl/Intermediate-CA.crl" \
-out $1-csr.pem

openssl x509 -req -sha256 -days 365 -in $1-csr.pem -CA $3.crt -CAkey $3.key -CAcreateserial \
-extfile - <<<"subjectAltName = DNS:localhost,DNS:*.localhost,DNS:$1,DNS:$1.$DOMAIN,IP:127.0.0.1,IP:$2$EXTRA_SAN
basicConstraints = CA:FALSE
extendedKeyUsage = clientAuth,serverAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid, issuer
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, keyAgreement, dataEncipherment
authorityInfoAccess = caIssuers;URI:http://localhost:8000/Intermediate-CA.cer,OCSP;URI:http://localhost:8000/ocsp
crlDistributionPoints = URI:http://localhost:8000/crl/Root-CA.crl,URI:http://localhost:8000/crl/Intermediate-CA.crl" \
-out $1.crt

printf "\nPrinting Certificate...\n"
# openssl req -noout -text -in $1-csr.pem
openssl x509 -text -noout -in $1.crt

printf "\nPrinting Digest of crt, key and csr. All values must be the same...\n"
openssl pkey -in $1.key  -pubout | openssl dgst -sha256 -r | cut -d' ' -f1
openssl x509 -in $1.crt -pubkey -noout | openssl dgst -sha256 -r | cut -d' ' -f1
openssl req -in $1-csr.pem -pubkey -noout | openssl dgst -sha256 -r | cut -d' ' -f1
