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

printf "\nMaking ETCD Root CA...\n"
openssl genpkey -algorithm EC -pkeyopt ec_paramgen_curve:secp521r1 -pkeyopt ec_param_enc:named_curve -out etcd-ca.key
# openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:4096 -out etcd-ca.key

openssl req -new -sha256 -x509 -key etcd-ca.key -days 7300 \
-subj "/C=CA/ST=QC/L=Montreal/O=RootCA/OU=IT/CN=rootca.com" \
-addext "subjectAltName = DNS:localhost,DNS:*.localhost,DNS:rootca.com,IP:127.0.0.1" \
-addext "basicConstraints = critical,CA:TRUE" \
-addext "keyUsage = critical, digitalSignature, cRLSign, keyCertSign" \
-addext "subjectKeyIdentifier = hash" \
-addext "authorityKeyIdentifier = keyid:always, issuer" \
-addext "authorityInfoAccess = caIssuers;URI:http://localhost:8000/Intermediate-CA.cer,OCSP;URI:http://localhost:8000/ocsp" \
-addext "crlDistributionPoints = URI:http://localhost:8000/crl/Root-CA.crl,URI:http://localhost:8080/crl/Intermediate-CA.crl" \
-out etcd-ca.crt

openssl x509 -text -noout -in etcd-ca.crt
echo "PubKey: $(openssl x509 -pubkey -in etcd-ca.crt -noout | openssl md5 | awk -F '= ' '{print $2}')"
echo "PubKey: $(openssl pkey -pubout -in etcd-ca.key | openssl md5 | awk -F '= ' '{print $2}')"
