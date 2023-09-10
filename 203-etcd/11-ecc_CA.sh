#!/bin/bash
#
# This script generates certificates for a fake RootCA using ECC keys.
# The CA has 521-bit private key.
# All the files are in 'pem' format. The private key is NOT encrypted and is in PKCS#8 format.
#
# The following files are generated in the current directory:
#   etcd-ca.crt          ETCD Root CA private key
#   etcd-ca.key          ETCD Root CA certificate
#
# HOWTO use it: ./ecc_gen_chain.sh
#
# Works with 'bash' and 'zsh' shell on macOS and Linux. Make sure you have OpenSSL *** in your PATH ***.
#
# *WARNING*
# This script was made for educational purposes ONLY.
# USE AT YOUR OWN RISK!"

if [[ $# -ne 1 ]]
then
   printf "\nUsage: %s <filename prefix of CA>\n" $(basename $0)
   printf "\tEx.: %s etcd-ca\n\n" $(basename $0)
   exit -1
fi

printf "\nMaking ETCD Root CA...\n"
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:secp521r1 -pkeyopt ec_param_enc:named_curve -out $1.key
# Comment the line above and uncomment the line below if you want an RSA key
# openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out $1.key

openssl req -new -sha256 -x509 -key $1.key -days 7300 \
-subj "/C=CA/ST=QC/L=Montreal/O=RootCA/OU=IT/CN=rootca.com" \
-addext "subjectAltName = DNS:localhost,DNS:*.localhost,DNS:rootca.com,IP:127.0.0.1" \
-addext "basicConstraints = critical,CA:TRUE" \
-addext "keyUsage = critical, digitalSignature, cRLSign, keyCertSign" \
-addext "subjectKeyIdentifier = hash" \
-addext "authorityKeyIdentifier = keyid:always, issuer" \
-addext "authorityInfoAccess = caIssuers;URI:http://localhost:8000/Intermediate-CA.cer,OCSP;URI:http://localhost:8000/ocsp" \
-addext "crlDistributionPoints = URI:http://localhost:8000/crl/Root-CA.crl,URI:http://localhost:8080/crl/Intermediate-CA.crl" \
-out $1.crt

# Print the certificate
openssl x509 -text -noout -in $1.crt

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
