package kafka

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"os"
	"path/filepath"

	"github.com/segmentio/kafka-go/sasl/scram"
)

func NewKafka(setting Setting) (RepositoryI, error) {
	ca := filepath.Join(setting.Path, "ca.crt")
	crt := filepath.Join(setting.Path, "client.crt")
	key := filepath.Join(setting.Path, "client.key")
	cert, err := tls.LoadX509KeyPair(crt, key)
	if err != nil {
		return &repository{}, fmt.Errorf("LoadX509KeyPair:%w", err)
	}

	// Load CA
	caCert, err := os.ReadFile(ca)
	if err != nil {
		return &repository{}, fmt.Errorf("ReadFile:%w", err)
	}
	caCertPool := x509.NewCertPool()
	caCertPool.AppendCertsFromPEM(caCert)

	// TLS config
	tlsConfig := &tls.Config{
		Certificates:       []tls.Certificate{cert}, // client cert + key
		RootCAs:            caCertPool,              // trust broker CA
		InsecureSkipVerify: false,
	}

	// SASL PLAIN config
	// sasl := plain.Mechanism{
	// 	Username: setting.Username,
	// 	Password: setting.Password,
	// }

	// === SCRAM mechanism ===
	sasl, err := scram.Mechanism(scram.SHA512, setting.Username, setting.Password)
	if err != nil {
		return nil, fmt.Errorf("scram mechanism:%w", err)
	}

	return &repository{
		setting:   setting,
		tlsConfig: tlsConfig,
		sasl:      sasl,
	}, nil
}
