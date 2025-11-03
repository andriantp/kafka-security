# Makefile 

TLS_FILE   = docker/tls.docker-compose.yml
SASL_FILE  = docker/sasl.docker-compose.yml
SCRAM_FILE = docker/scram.docker-compose.yml
KEY_FILE   = docker/keycloak.docker-compose.yml
OAUTH_FILE = docker/oauth.docker-compose.yml

BROKER     = broker:9096
SCRAM_USER = scram-user
SCRAM_PASS = scram-secret

# ======================== docker ========================  
volume:
	docker volume prune -a -f 
system: 
	docker system prune -a -f

# ======================== certs ========================  
certs:
	@echo "🔑 Generating certificates..."
	chmod +x security/generate-certs.sh
	./security/generate-certs.sh

	@echo "Permission {ca.crt,client.crt,client.key}"
	chmod 644 docker/certs/ca.crt
	chmod 644 docker/certs/client.crt
	chmod 644 docker/certs/client.key

	@echo "✅ Certificates generated done"


# ======================== TLS ========================  
tls-up:
	@echo "🐳 Starting (Kafka & AKHQ) with TLS containers..."
	chmod -R 777 docker/kafka
	docker compose -f $(TLS_FILE) up --force-recreate -d --build 
	@echo "✅ (Kafka & AKHQ) with TLS are up"

tls-down:
	@echo "🛑 Stopping (Kafka + AKHQ) with TLS containers..."
	docker compose -f $(TLS_FILE) down
	@echo "✅ Containers stopped"


# ======================== SASL ========================
sasl-up:
	@echo "🐳 Starting (Kafka & AKHQ) with SASL containers..."
	chmod -R 777 docker/kafka
	docker compose -f $(SASL_FILE) up --force-recreate -d --build 
	@echo "✅ (Kafka & AKHQ) with SASL are up"

sasl-down:
	@echo "🛑 Stopping (Kafka + AKHQ) with SASL containers..."
	docker compose -f $(SASL_FILE) down
	@echo "✅ Containers stopped"


# ======================== SCRAM ======================== 
scram-up:
	@echo "🐳 Starting (Kafka & AKHQ) with SCRAM containers..."
	chmod -R 777 docker/kafka
	docker compose -f $(SCRAM_FILE) up -d
	@echo "✅ (Kafka & AKHQ) with SCRAM are up"

scram-down:
	@echo "🛑 Stopping (Kafka + AKHQ) with SCRAM containers..."
	docker compose -f $(SCRAM_FILE) down
	@echo "✅ Containers stopped"

# create user admin
scram-admin:
	docker exec -it kafka \
		kafka-configs --alter \
		--bootstrap-server localhost:9093 \
		--add-config 'SCRAM-SHA-512=[password=admin-secret]' \
		--entity-type users \
		--entity-name admin \
		--command-config /etc/kafka/secrets/admin.properties

# Command untuk create/update user SCRAM
scram-user:
	docker exec -it kafka \
		kafka-configs --alter \
		--bootstrap-server $(BROKER) \
		--add-config 'SCRAM-SHA-512=[password=$(SCRAM_PASS)]' \
		--entity-type users \
		--entity-name $(SCRAM_USER) \
		--command-config /etc/kafka/secrets/client.properties

# Cek user yang ada
scram-list:
	docker exec -it kafka \
		kafka-configs --describe \
		--bootstrap-server $(BROKER) \
		--entity-type users \
		--command-config /etc/kafka/secrets/client.properties


# ======================== oauth ========================  


# ======================== log ========================  
logs:
	@echo "📜 Showing Kafka logs..."
	docker logs -f kafka

logs-akhq:
	@echo "📜 Showing AKHQ logs..."
	docker logs -f akhq

ps:
	@echo "📋 Checking container status..."
	docker ps -a

