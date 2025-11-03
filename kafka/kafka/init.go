package kafka

import (
	"context"
	"crypto/tls"

	"github.com/segmentio/kafka-go/sasl"
)

type Setting struct {
	Path    string
	Broker  string
	Topic   string
	GroupID string

	Username string
	Password string
}

type repository struct {
	setting   Setting
	tlsConfig *tls.Config
	// sasl      plain.Mechanism
	sasl sasl.Mechanism

	token OAuthToken
}

type RepositoryI interface {
	Producer(ctx context.Context, msg string) error
	Consumer(ctx context.Context) error

	ProduceAuth(message string) error
	ConsumeAuth(ctx context.Context) error
}
