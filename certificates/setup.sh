#!/bin/bash

BASEDIR=$(dirname "$0")

set -e

# Root CA
openssl genrsa -out $BASEDIR/ca/root-ca/root-ca-key.pem 2048 
openssl req -days 3650 -new -x509 -sha256 -key $BASEDIR/ca/root-ca/root-ca-key.pem -out $BASEDIR/ca/root-ca/root-ca.pem -batch -verbose -config $BASEDIR/ca/root-ca/root-ca.conf
openssl x509 -subject -nameopt RFC2253 -noout -in $BASEDIR/ca/root-ca/root-ca.pem

# Admin cert
openssl genrsa -out $BASEDIR/admin/admin-key-temp.pem 2048 
openssl pkcs8 -inform PEM -outform PEM -in $BASEDIR/admin/admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out $BASEDIR/admin/admin-key.pem 
openssl req -new -key $BASEDIR/admin/admin-key.pem -out $BASEDIR/admin/admin.csr -verbose -config $BASEDIR/admin/admin.conf
openssl x509 -req -days 365 -in $BASEDIR/admin/admin.csr -CA $BASEDIR/ca/root-ca/root-ca.pem -CAkey $BASEDIR/ca/root-ca/root-ca-key.pem -CAcreateserial -sha256 -out $BASEDIR/admin/admin.pem 
openssl x509 -subject -nameopt RFC2253 -noout -in $BASEDIR/admin/admin.pem 
# Admin keystore
rm -f $BASEDIR/admin/admin.keystore

openssl pkcs12 -export -name admin -out $BASEDIR/admin/admin.p12 -inkey $BASEDIR/admin/admin-key.pem -passout "pass:92cdf688aac64d17b230" -in $BASEDIR/admin/admin.pem -CAfile $BASEDIR/ca/root-ca/root-ca.pem

# Node cert
openssl genrsa -out $BASEDIR/transport/node-key-temp.pem 2048 
openssl pkcs8 -inform PEM -outform PEM -in $BASEDIR/transport/node-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out $BASEDIR/transport/node-key.pem
openssl req -new -key $BASEDIR/transport/node-key.pem -out $BASEDIR/transport/node.csr -batch -verbose -config $BASEDIR/transport/transport.conf
openssl x509 -req -days 365 -in $BASEDIR/transport/node.csr -CA $BASEDIR/ca/root-ca/root-ca.pem -CAkey $BASEDIR/ca/root-ca/root-ca-key.pem -CAcreateserial -sha256 -out $BASEDIR/transport/node.pem
openssl x509 -subject -nameopt RFC2253 -noout -in $BASEDIR/transport/node.pem

openssl pkcs12 -export -name node -out $BASEDIR/transport/node.p12 -inkey $BASEDIR/transport/node-key.pem -passout "pass:92cdf688aac64d17b230" -in $BASEDIR/transport/node.pem -CAfile $BASEDIR/ca/root-ca/root-ca.pem

# ELK Rest cert
openssl genrsa -out $BASEDIR/elk-rest/elk-rest-key-temp.pem 2048 
openssl pkcs8 -inform PEM -outform PEM -in $BASEDIR/elk-rest/elk-rest-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out $BASEDIR/elk-rest/elk-rest-key.pem
openssl req -new -key $BASEDIR/elk-rest/elk-rest-key.pem -out $BASEDIR/elk-rest/elk-rest.csr -batch -verbose -config $BASEDIR/elk-rest/elk-rest.conf
openssl x509 -req -days 365 -in $BASEDIR/elk-rest/elk-rest.csr -CA $BASEDIR/ca/root-ca/root-ca.pem -CAkey $BASEDIR/ca/root-ca/root-ca-key.pem -CAcreateserial -sha256 -out $BASEDIR/elk-rest/elk-rest.pem
openssl x509 -subject -nameopt RFC2253 -noout -in $BASEDIR/elk-rest/elk-rest.pem

openssl pkcs12 -export -name elk-rest -out $BASEDIR/elk-rest/elk-rest.p12 -inkey $BASEDIR/elk-rest/elk-rest-key.pem -passout "pass:92cdf688aac64d17b230" -in $BASEDIR/elk-rest/elk-rest.pem -CAfile $BASEDIR/ca/root-ca/root-ca-key.pem


# elasticsearch truststore (to connect to IdP)
rm -f $BASEDIR/ca/elasticsearch.truststore
keytool -import -file $BASEDIR/ca/catruststore/DigiCertSHA2SecureServerCA.crt -alias DigiCertSHA2SecureServerCA -keystore $BASEDIR/ca/elasticsearch.truststore -storepass 92cdf688aac64d17b230 -noprompt
keytool -import -file $BASEDIR/ca/catruststore/DigiCertGlobalRootCA.crt -alias DigiCertGlobalRootCA -keystore $BASEDIR/ca/elasticsearch.truststore -storepass 92cdf688aac64d17b230 -noprompt

# in-cluster ca truststore
rm -f $BASEDIR/ca/http.truststore

keytool -import -file $BASEDIR/ca/root-ca/root-ca.pem -alias RootCA -keystore $BASEDIR/ca/http.truststore -storepass 92cdf688aac64d17b230 -noprompt

keytool -importkeystore -alias elk-rest -deststorepass 92cdf688aac64d17b230 -destkeystore keystore.jks -srckeystore $BASEDIR/elk-rest/elk-rest.p12 -srcstorepass 92cdf688aac64d17b230 -noprompt
keytool -importkeystore -alias admin -deststorepass 92cdf688aac64d17b230 -destkeystore keystore.jks -srckeystore $BASEDIR/admin/admin.p12 -srcstorepass 92cdf688aac64d17b230 -noprompt
keytool -importkeystore -alias node -deststorepass 92cdf688aac64d17b230 -destkeystore keystore.jks -srckeystore $BASEDIR/transport/node.p12 -srcstorepass 92cdf688aac64d17b230 -noprompt

#cleanup
find $BASEDIR -type f -name "*-temp.pem" -delete
find $BASEDIR -type f -name "*.srl" -delete
