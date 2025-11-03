#!/bin/bash
set -e

IN=../docker/certs/jwks/jwt_public.pem
OUT=../docker/certs/jwks/jwks.json
KID="jwt-key-1"

# ambil modulus (n) dan exponent (e) dari public key
read -r n e <<<$(openssl rsa -in "$IN" -pubin -text -noout \
  | awk '/Modulus:/{flag=1;next}/Exponent:/{flag=0}
         flag {gsub(/[: ]/, "", $0); printf "%s", $0}
         /Exponent:/ {print " " $2}' \
  | xargs -n2 echo)

# ubah ke base64url (hapus =, + → -, / → _)
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

n_b64=$(echo "$n" | xxd -r -p | b64url)
e_b64=$(printf '%x' "$e" | xxd -r -p | b64url)

cat > "$OUT" <<EOF
{
  "keys": [
    {
      "kty": "RSA",
      "use": "sig",
      "kid": "$KID",
      "alg": "RS256",
      "n": "$n_b64",
      "e": "$e_b64"
    }
  ]
}
EOF

echo "JWKS generated at $OUT"
