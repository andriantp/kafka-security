#!/bin/bash

set -e

OUT="../docker/certs"
mkdir -p $OUT/jwks

# 1. generate private key (RSA 2048)
openssl genrsa -out $OUT/jwks/jwt_private.pem 2048

# 2. extract public key (PEM)
openssl rsa -in $OUT/jwks/jwt_private.pem -pubout -out $OUT/jwks/jwt_public.pem

echo "Keys generated under $OUT/jwks"

