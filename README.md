# Kafka Security & Governance

This repository is the companion project for the article  
👉 [**Golang x Kafka #8: Security & Governance**](https://andriantriputra.medium.com/golang-x-kafka-8-security-governance-4661602c31db)  
by [Andrian Tri Putra](https://github.com/andriantp)

It provides a **hands-on setup** to explore Kafka security mechanisms — including SSL/TLS encryption, SASL authentication, and Access Control Lists (ACLs) — using **Docker** and **Golang** clients.

---

## Overview

Apache Kafka is powerful, but by default it runs in **plaintext mode** without authentication or encryption.  
This project demonstrates how to enable **security and governance** across a Kafka cluster, focusing on:

1. **Confidentiality** -> enabling SSL/TLS between brokers, producers, and consumers.  
2. **Authentication** -> enforcing SASL mechanisms (PLAIN, SCRAM, or OAuth).  
3. **Authorization** -> managing ACLs to control topic-level access.  
4. **Governance** -> defining retention, compaction, and auditing strategies.

---

## Repository Structure

```bash
kafka-security/
├── docker/
│   ├── docker-compose.yml        # Kafka, Zookeeper, and security-enabled services
│   ├── certs/                    # SSL certificates (auto-generated or prebuilt)
│   └── scripts/                  # Helper scripts for setup & testing
├── kafka/
│   ├── producer.go               # Example Golang producer (with SASL/SSL)
│   ├── consumer.go               # Example Golang consumer (with SASL/SSL)
│   └── config/                   # Kafka client configuration templates
└── security/
    ├── acl.sh                    # Script for managing ACLs
    ├── sasl_config.properties    # SASL configuration samples
    └── ssl_config.properties     # SSL configuration samples
```

---
## Quick Start
1. Clone the repository
```bash
$ git clone https://github.com/andriantp/kafka-security.git
$ cd kafka-security
```

2. Generate certificates (optional)
If you want to regenerate SSL certificates:
```bash
$ cd docker
$ make certs
```

3. Start Kafka with security enabled
```bash
$ cd docker

# TLS only
$ make tls-up

# or SASL + TLS
$ make sasl-up

```
This spins up a Kafka cluster with SSL/TLS and SASL enabled, along with preconfigured certificates.


4. Produce & consume securely
```bash
Use the Golang examples:
$ cd kafka
$ go mod tidy
$ go run . consumer
$ go run . producer
```
Both examples use config/ files for SASL and SSL configuration.

---

## Key Concepts
| Concept        | Description                                                               |
| -------------- | ------------------------------------------------------------------------- |
| **SSL/TLS**    | Encrypts communication between Kafka brokers and clients.                 |
| **SASL**       | Provides authentication mechanisms (PLAIN, SCRAM, OAUTHBEARER).           |
| **ACLs**       | Defines which users can produce or consume from specific topics.          |
| **Governance** | Includes retention policies, log compaction, and auditing for compliance. |

---
## Reference Article

Read the full explanation here:

📄 [Golang x Kafka #8: Security & Governance](https://andriantriputra.medium.com/golang-x-kafka-8-security-governance-4661602c31db)

That article walks through:
- The theory behind Kafka security layers
- Practical configuration for SSL/TLS, SASL, and ACLs
- Governance considerations for production systems

---

## Future Work
- Add OAuth2 authentication for enterprise environments
- Integrate with Prometheus/Grafana for security monitoring
- Extend governance layer for audit logging
- Deploy to Kubernetes with secure secrets management

---
## Author

Andrian Tri Putra
- [Medium](https://andriantriputra.medium.com/)
- [andriantp](https://github.com/andriantp)
- [AndrianTriPutra](https://github.com/AndrianTriPutra)

---

## License
Licensed under the Apache License 2.0

