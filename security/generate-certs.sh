#!/usr/bin/env bash
set -euo pipefail

PASSWORD="changeit"

# BASE_DIR="$(pwd)"
# OUT_DIR="${BASE_DIR}/docker/certs"
# SEC_DIR="${BASE_DIR}/docker/secrets"
OUT_DIR="../docker/certs"
SEC_DIR="../docker/secrets"

mkdir -p "$OUT_DIR" "$SEC_DIR"

echo "OUT_DIR: $OUT_DIR"
echo "SEC_DIR: $SEC_DIR"

CA_KEY="$OUT_DIR/ca.key"
CA_CERT="$OUT_DIR/ca.crt"
CA_SRL="$OUT_DIR/ca.srl"

BROKER_KEY="$OUT_DIR/broker.key"
BROKER_CSR="$OUT_DIR/broker.csr"
BROKER_CERT="$OUT_DIR/broker.crt"
BROKER_P12="$OUT_DIR/broker.p12"
BROKER_KEYSTORE="$OUT_DIR/broker.keystore.jks"
BROKER_TRUSTSTORE="$OUT_DIR/broker.truststore.jks"

CLIENT_KEY="$OUT_DIR/client.key"
CLIENT_CSR="$OUT_DIR/client.csr"
CLIENT_CERT="$OUT_DIR/client.crt"
CLIENT_P12="$OUT_DIR/client.p12"
CLIENT_KEYSTORE="$OUT_DIR/client.keystore.jks"
CLIENT_TRUSTSTORE="$OUT_DIR/client.truststore.jks"

echo "=== Creating CA ==="
openssl genrsa -out "$CA_KEY" 4096
openssl req -x509 -new -nodes -key "$CA_KEY" -sha256 -days 3650 \
  -out "$CA_CERT" -subj "/CN=local-ca"

# -------------------
# Broker Certificate
# -------------------
echo "=== Creating Broker Cert ==="
openssl genrsa -out "$BROKER_KEY" 4096

SAN_CONF="$OUT_DIR/broker_san.cnf"
cat > "$SAN_CONF" <<'EOF'
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = broker
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

openssl req -new -key "$BROKER_KEY" -out "$BROKER_CSR" -subj "/CN=broker" -config "$SAN_CONF"
openssl x509 -req -in "$BROKER_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
  -out "$BROKER_CERT" -days 365 -sha256 -extensions v3_req -extfile "$SAN_CONF"

echo "Packaging Broker cert into JKS..."
openssl pkcs12 -export -in "$BROKER_CERT" -inkey "$BROKER_KEY" -certfile "$CA_CERT" \
  -name broker -out "$BROKER_P12" -passout pass:$PASSWORD

keytool -importkeystore \
  -srckeystore "$BROKER_P12" -srcstoretype PKCS12 -srcstorepass $PASSWORD \
  -destkeystore "$BROKER_KEYSTORE" -deststorepass $PASSWORD -destkeypass $PASSWORD -alias broker

keytool -import -file "$CA_CERT" -alias CARoot \
  -keystore "$BROKER_TRUSTSTORE" -storepass $PASSWORD -noprompt

# -------------------
# Client Certificate
# -------------------
echo "=== Creating Client Cert ==="
openssl genrsa -out "$CLIENT_KEY" 4096

CLIENT_CONF="$OUT_DIR/client_ext.cnf"
cat > "$CLIENT_CONF" <<'EOF'
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
[req_distinguished_name]
[v3_req]
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

openssl req -new -key "$CLIENT_KEY" -out "$CLIENT_CSR" -subj "/CN=kafka-client"
openssl x509 -req -in "$CLIENT_CSR" -CA "$CA_CERT" -CAkey "$CA_KEY" -CAcreateserial \
  -out "$CLIENT_CERT" -days 365 -sha256 -extensions v3_req -extfile "$CLIENT_CONF"

echo "Packaging Client cert into JKS..."
openssl pkcs12 -export -in "$CLIENT_CERT" -inkey "$CLIENT_KEY" -certfile "$CA_CERT" \
  -name client -out "$CLIENT_P12" -passout pass:$PASSWORD

keytool -importkeystore \
  -srckeystore "$CLIENT_P12" -srcstoretype PKCS12 -srcstorepass $PASSWORD \
  -destkeystore "$CLIENT_KEYSTORE" -deststorepass $PASSWORD -destkeypass $PASSWORD -alias client

keytool -import -file "$CA_CERT" -alias CARoot \
  -keystore "$CLIENT_TRUSTSTORE" -storepass $PASSWORD -noprompt

# -------------------
# Finalize
# -------------------
echo "=== Done! Files created in: $OUT_DIR ==="
ls -1 "$OUT_DIR" | grep -E 'crt|jks|key|p12$'

echo "🔑 Creating credential files..."
echo "$PASSWORD" > "$SEC_DIR/keystore_creds"
echo "$PASSWORD" > "$SEC_DIR/key_creds"
echo "$PASSWORD" > "$SEC_DIR/truststore_creds"

cp "$BROKER_KEYSTORE" "$SEC_DIR/"
cp "$BROKER_TRUSTSTORE" "$SEC_DIR/"

echo "✅ Secrets ready in $SEC_DIR"
