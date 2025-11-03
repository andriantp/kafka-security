package kafka

import (
	"context"
	"fmt"
	"time"

	"github.com/segmentio/kafka-go"
)

func (r *repository) Consumer(ctx context.Context) error {
	reader := kafka.NewReader(
		kafka.ReaderConfig{
			Brokers: []string{r.setting.Broker},
			Topic:   r.setting.Topic,
			GroupID: r.setting.GroupID,

			Dialer: &kafka.Dialer{
				Timeout:       10 * time.Second,
				TLS:           r.tlsConfig, // TLS
				SASLMechanism: r.sasl,      // kalau aktifkan SASL
			},
		})

	fmt.Println("📥 Consumer started, waiting for messages...")

	for {
		m, err := reader.ReadMessage(ctx)
		if err != nil {
			return fmt.Errorf("failed to read message: %w", err)
		}
		fmt.Printf("✅ message received: %s\n", string(m.Value))
	}
}

