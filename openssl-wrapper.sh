#!/bin/sh

export SAN=""

if [ -n "${UNSAFE_CA+x}" ]; then
  echo "Creating insecure CA for testing"
  _ENCRYPT=""
  _AUTO="yes | "
  _OUTPUT=" > /dev/null 2>&1"
else
  _ENCRYPT="-aes256"
  _AUTO=""
  _OUTPUT=""
fi

#init
if [ ! -f "./private/ca.key.pem" ]; then
  echo ""
  echo "CREATING ROOT CERTIFICATE"

  eval "openssl genrsa $_ENCRYPT -out private/ca.key.pem 4096 $_OUTPUT"
  chmod 400 private/ca.key.pem

  eval "openssl req -config openssl.cnf \
  -new -x509 \
  -key private/ca.key.pem \
  -subj \"/C=GB/ST=England/O=Alice Ltd/OU=Certificates/CN=root.ca.alice.fake\" \
  -days 7300 -sha256 \
  -out certs/ca.cert.pem $_OUTPUT"
  chmod 444 certs/ca.cert.pem

  echo ""
  echo "CREATING INTERMEDIATE CERTIFICATE"

  eval "openssl genrsa $_ENCRYPT \
    -out intermediate/private/intermediate.key.pem 4096 $_OUTPUT"
  chmod 400 intermediate/private/intermediate.key.pem

  eval "openssl req -config intermediate/openssl.cnf -new -sha256 \
    -key intermediate/private/intermediate.key.pem \
    -subj \"/C=GB/ST=England/O=Alice Ltd/OU=Certificates/CN=inter.ca.alice.fake\" \
    -out intermediate/csr/intermediate.csr.pem $_OUTPUT"

  eval "$_AUTO openssl ca -config openssl.cnf -extensions v3_intermediate_ca \
    -days 3650 -notext -md sha256 \
    -in intermediate/csr/intermediate.csr.pem \
    -out intermediate/certs/intermediate.cert.pem $_OUTPUT"
  chmod 444 intermediate/certs/intermediate.cert.pem

  cat intermediate/certs/intermediate.cert.pem \
    certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem
  chmod 444 intermediate/certs/ca-chain.cert.pem

  echo ""
  echo "Extract the root certificate using docker cp $(hostname):/root/ca/certs/ca.cert.pem ./ca.cert.pem"
  echo "Extract the intermediate certificate using docker cp $(hostname):/root/ca/intermediate/certs/intermediate.cert.pem ./intermediate.cert.pem"
fi

if [ "$1" == "server" ]; then
  if [ $# -gt 1 ]; then
    _CERT_NAME="$2"
  else
    printf "Server cert name: "
    read
    _CERT_NAME="$REPLY"
  fi

  if [ $# -gt 2 ]; then
    _DNS_NAME="$3"
  else
    printf "Server DNS name: "
    read
    _DNS_NAME="$REPLY"
  fi

  export SAN="DNS:$_DNS_NAME"

  _PRIVATE_KEY="intermediate/private/$_CERT_NAME.key.pem"
  _CSR="intermediate/csr/$_CERT_NAME.csr.pem"
  _CERT="intermediate/certs/$_CERT_NAME.cert.pem"

  echo ""
  echo "CREATING SERVER CERTIFICATE: $_CERT_NAME"

  eval "openssl genrsa $_ENCRYPT -out \"$_PRIVATE_KEY\" 2048 $_OUTPUT"
  chmod 400 "$_PRIVATE_KEY"

  eval "openssl req -config intermediate/openssl.cnf \
    -subj \"/C=GB/ST=England/O=Alice Ltd/OU=Servers/CN=$_DNS_NAME\" \
    -key \"$_PRIVATE_KEY\" -new -sha256 -out \"$_CSR\" $_OUTPUT"

  eval "$_AUTO openssl ca -config intermediate/openssl.cnf \
    -extensions server_cert -days 375 -notext -md sha256 \
    -in \"$_CSR\" -out \"$_CERT\" $_OUTPUT"
  chmod 400 "$_CERT"

  echo ""
  echo "Extract the server key using docker cp $(hostname):/root/ca/$_PRIVATE_KEY ./$_CERT_NAME.key.pem"
  echo "Extract the server cert using docker cp $(hostname):/root/ca/$_CERT ./$_CERT_NAME.cert.pem"

elif [ "$1" == "client" ]; then
  if [ $# -gt 1 ]; then
    _CERT_NAME="$2"
  else
    printf "Client cert name: "
    read
    _CERT_NAME="$REPLY"
  fi

  if [ $# -gt 2 ]; then
    _COMMON_NAME="$3"
  else
    printf "Client common name: "
    read
    _COMMON_NAME="$REPLY"
  fi

  _PRIVATE_KEY="intermediate/private/$_CERT_NAME.key.pem"
  _CSR="intermediate/csr/$_CERT_NAME.csr.pem"
  _CERT="intermediate/certs/$_CERT_NAME.cert.pem"
  
  echo ""
  echo "CREATING CLIENT CERTIFICATE: $_CERT_NAME"

  eval "openssl genrsa $_ENCRYPT -out \"$_PRIVATE_KEY\" 2048 $_OUTPUT"
  chmod 400 "$_PRIVATE_KEY"

  eval "openssl req -config intermediate/openssl.cnf \
    -subj \"/C=GB/ST=England/O=Alice Ltd/OU=Clients/CN=$_COMMON_NAME\" \
    -key \"$_PRIVATE_KEY\" -new -sha256 -out \"$_CSR\" $_OUTPUT"

  eval "$_AUTO openssl ca -config intermediate/openssl.cnf \
    -extensions usr_cert -days 375 -notext -md sha256 \
    -in \"$_CSR\" -out \"$_CERT\" $_OUTPUT"
  chmod 400 "$_CERT"

  echo ""
  echo "Extract the server key using docker cp $(hostname):/root/ca/$_PRIVATE_KEY ./$_CERT_NAME.key.pem"
  echo "Extract the server cert using docker cp $(hostname):/root/ca/$_CERT ./$_CERT_NAME.cert.pem"

fi

# https://jamielinux.com/docs/openssl-certificate-authority/sign-server-and-client-certificates.html
