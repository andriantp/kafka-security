package kafka

import (
	"context"
	"fmt"

	"github.com/segmentio/kafka-go"
)

func (r *repository) Producer(ctx context.Context, msg string) error {
	w := kafka.Writer{
		Addr:  kafka.TCP(r.setting.Broker),
		Topic: r.setting.Topic,
		Transport: &kafka.Transport{
			TLS:  r.tlsConfig, // TLS
			SASL: r.sasl,      //SASL
		},
	}

	if err := w.WriteMessages(ctx,
		kafka.Message{
			//Key: []byte(""),
			Value: []byte(msg)},
	); err != nil {
		return fmt.Errorf("failed to write:%w", err)
	}

	return nil
}
