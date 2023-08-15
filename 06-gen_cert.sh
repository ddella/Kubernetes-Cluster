#!/bin/sh

# Generate a new private/public key pair and a certificate for a server.
#
# ***** This script assume the following: *****
#     Certificate filename: <name>-crt.pem
#     CSR filename:         <name>-csr.pem
#     Private key filename: <name>-key.pem
#
# This is a bit dirty, but helps when you want to generate lots of certificate
# for testing. Was made to work in conjunction with:
# https://gist.github.com/ddella/c2bc100a091bc59f51b740a4f3663b75
#
# HOWTO use it: ./gen_cert.sh server1 intermediate-ca
#
# This will generate the following files:
#  -rw-r--r--   1 username  staff  1216 01 Jan 00:00 server1-crt.pem >> certificate
#  -rw-r--r--   1 username  staff   976 01 Jan 00:00 server1-csr.pem >> CSR
#  -rw-------   1 username  staff   302 01 Jan 00:00 server1-key.pem >> key pair
#
# Works with 'bash' and 'zsh' shell on macOS and Linux.

# Hostname
export HOSTNAME='k8sapi'
# This is just the filenames for key, csr and cer
export CERT_NAME='k8sapiserver'
# Your domain
export DOMAIN='isociel.com'
# The reverse proxy endpoint or the VRRP endpoint
export EXTRA_SAN=",DNS:${HOSTNAME},DNS:${HOSTNAME}.${DOMAIN},IP:192.168.13.60"

printf "\nMaking certificate: ${HOSTNAME} ...\n"
openssl ecparam -name prime256v1 -genkey -out ${CERT_NAME}.key

openssl req -new -sha256 -key ${CERT_NAME}.key -subj "/C=CA/ST=QC/L=Montreal/O=$1/OU=IT/CN=${HOSTNAME}.${DOMAIN}" \
-addext "subjectAltName = DNS:localhost,IP:127.0.0.1${EXTRA_SAN}" \
-addext "basicConstraints = CA:FALSE" \
-addext "extendedKeyUsage = clientAuth,serverAuth" \
-addext "subjectKeyIdentifier = hash" \
-addext "keyUsage = nonRepudiation, digitalSignature, keyEncipherment, keyAgreement, dataEncipherment" \
-addext "authorityInfoAccess = caIssuers;URI:http://localhost:8000/Intermediate-CA.cer,OCSP;URI:http://localhost:8000/ocsp" \
-addext "crlDistributionPoints = URI:http://localhost:8000/crl/Root-CA.crl,URI:http://localhost:8080/crl/Intermediate-CA.crl" \
-out ${CERT_NAME}.csr

openssl x509 -req -sha256 -days 365 -in $1-csr.pem -CA $3-crt.pem -CAkey $3-key.pem -CAcreateserial \
-extfile - <<<"subjectAltName = DNS:localhost,DNS:*.localhost,DNS:$1.$DOMAIN,IP:127.0.0.1,IP:$2$EXTRA_SAN
basicConstraints = CA:FALSE
extendedKeyUsage = clientAuth,serverAuth
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid, issuer
keyUsage = nonRepudiation, digitalSignature, keyEncipherment, keyAgreement, dataEncipherment
authorityInfoAccess = caIssuers;URI:http://localhost:8000/Intermediate-CA.cer,OCSP;URI:http://localhost:8000/ocsp
crlDistributionPoints = URI:http://localhost:8000/crl/Root-CA.crl,URI:http://localhost:8000/crl/Intermediate-CA.crl" \
-out ${CERT_NAME}.crt

printf "\nPrinting Certificate...\n"
# openssl req -noout -text -in $1-csr.pem
openssl x509 -text -noout -in ${CERT_NAME}.crt

printf "\nPrinting Digest of crt, key and csr. All values must be the same...\n"
openssl pkey -in ${CERT_NAME}.key  -pubout | openssl dgst -sha256 -r | cut -d' ' -f1
openssl x509 -in ${CERT_NAME}.crt -pubkey -noout | openssl dgst -sha256 -r | cut -d' ' -f1
openssl req -in ${CERT_NAME}.csr -pubkey -noout | openssl dgst -sha256 -r | cut -d' ' -f1
