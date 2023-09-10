#!/bin/bash

# Generate a new private/public key pair and a certificate for a server.
#
# ***** This script assume the following: *****
#     Certificate filename: <name>.crt
#     CSR filename:         <name>.csr
#     Private key filename: <name>.key
#
# This is a bit dirty, but helps when you want to generate lots of certificate
# for testing.
#
# HOWTO use it: ./gen_cert.sh k8setcd1 172.31.11.10 etcd-ca
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
   printf "\nUsage: %s <filename prefix> <IP address> <filename prefix of CA>\n" $(basename $0)
   printf "Ex.: %s k8setcd1 172.31.11.10 etcd-ca\n\n" $(basename $0)
   exit -1
fi

printf "\nMaking certificate: $1 ...\n"
openssl ecparam -name prime256v1 -genkey -out $1.key
# Comment the line above and uncomment the line below if you want an RSA key
# openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out $1.key

openssl req -new -sha256 -key $1.key -subj "/C=CA/ST=QC/L=Montreal/O=$1/OU=IT/CN=$1.$DOMAIN" \
-addext "subjectAltName = DNS:localhost,DNS:*.localhost,DNS:$1,DNS:$1.$DOMAIN,IP:127.0.0.1,IP:$2$EXTRA_SAN" \
-addext "basicConstraints = CA:FALSE" \
-addext "extendedKeyUsage = clientAuth,serverAuth" \
-addext "subjectKeyIdentifier = hash" \
-addext "keyUsage = nonRepudiation, digitalSignature, keyEncipherment, keyAgreement, dataEncipherment" \
-addext "authorityInfoAccess = caIssuers;URI:http://localhost:8000/Intermediate-CA.cer,OCSP;URI:http://localhost:8000/ocsp" \
-addext "crlDistributionPoints = URI:http://localhost:8000/crl/Root-CA.crl,URI:http://localhost:8080/crl/Intermediate-CA.crl" \
-out $1.csr

openssl x509 -req -sha256 -days 365 -in $1.csr -CA $3.crt -CAkey $3.key -CAcreateserial \
-extfile - <<<"subjectAltName = DNS:localhost,DNS:*.localhost,DNS:$1,DNS:$1.$DOMAIN,IP:127.0.0.1,IP:$2$EXTRA_SAN
basicConstraints = CA:FALSE
extendedKeyUsage = clientAuth,serverAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid, issuer
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, keyAgreement, dataEncipherment
authorityInfoAccess = caIssuers;URI:http://localhost:8000/Intermediate-CA.cer,OCSP;URI:http://localhost:8000/ocsp
crlDistributionPoints = URI:http://localhost:8000/crl/Root-CA.crl,URI:http://localhost:8000/crl/Intermediate-CA.crl" \
-out $1.crt

# To verify that etcd node certificate $1.crt is the CA $3.crt:
# openssl verify -no-CAfile -no-CApath -partial_chain -trusted %3.crt $1.crt

# Verification of certificate and private key. The next 2 checksum must be identical!
CRT_PUB=$(openssl x509 -pubkey -in $1.crt -noout | openssl sha256 | awk -F '= ' '{print $2}')
KEY_PUB=$(openssl pkey -pubout -in $1.key | openssl sha256 | awk -F '= ' '{print $2}')

if [[ "${CRT_PUB}" != "${KEY_PUB}" ]]
then
   printf "\nERROR: Public Key of certificate [%s] doesn't match Public Key of private key [%s].\n" $1.crt $1.key
   exit -1
else
   printf "\nSUCCESS: Public Key of certificate [%s] matches Public Key of private key [%s].\n" $1.crt $1.key
   exit 0
fi
