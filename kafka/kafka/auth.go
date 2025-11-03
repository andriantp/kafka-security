package kafka

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/confluentinc/confluent-kafka-go/v2/kafka"
)

type OAuthToken struct {
	AccessToken string `json:"access_token"`
	TokenType   string `json:"token_type"`
	ExpiresIn   int64  `json:"expires_in"`
}

func NewKafkAuth(token *OAuthToken, setting Setting) RepositoryI {
	return &repository{
		token:   *token,
		setting: setting,
	}
}

func GetToken(url string) (*OAuthToken, error) {
	resp, err := http.Post(url, "application/json", nil)
	if err != nil {
		return nil, fmt.Errorf("http request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("auth failed: %s", string(body))
	}

	var token OAuthToken
	if err := json.NewDecoder(resp.Body).Decode(&token); err != nil {
		return nil, fmt.Errorf("decode: %w", err)
	}
	return &token, nil
}

// ==============================
// 🧩 Kafka Producer
// ==============================
func (k *repository) ProduceAuth(message string) error {
	p, err := kafka.NewProducer(&kafka.ConfigMap{
		"bootstrap.servers": k.setting.Broker,
		"security.protocol": "SASL_PLAINTEXT",
		"sasl.mechanisms":   "OAUTHBEARER",
	})
	if err != nil {
		return fmt.Errorf("new producer: %w", err)
	}
	defer p.Close()

	err = p.SetOAuthBearerToken(kafka.OAuthBearerToken{
		TokenValue: k.token.AccessToken,
		Expiration: time.Now().Add(time.Duration(k.token.ExpiresIn) * time.Second),
	})
	if err != nil {
		return fmt.Errorf("set token: %w", err)
	}

	deliveryChan := make(chan kafka.Event)
	err = p.Produce(&kafka.Message{
		TopicPartition: kafka.TopicPartition{Topic: &k.setting.Topic, Partition: kafka.PartitionAny},
		Value:          []byte(message),
	}, deliveryChan)
	if err != nil {
		return fmt.Errorf("produce: %w", err)
	}

	e := <-deliveryChan
	m := e.(*kafka.Message)
	close(deliveryChan)

	if m.TopicPartition.Error != nil {
		return fmt.Errorf("delivery failed: %v", m.TopicPartition.Error)
	}

	return nil
}

// ----------------------------
// 🧩 Kafka Consumer
// ----------------------------
func (k *repository) ConsumeAuth(ctx context.Context) error {

	// buat consumer config
	config := &kafka.ConfigMap{
		"bootstrap.servers": k.setting.Broker,
		"group.id":          k.setting.GroupID,
		"auto.offset.reset": "earliest",
		"security.protocol": "SASL_PLAINTEXT",
		"sasl.mechanisms":   "OAUTHBEARER",
	}

	consumer, err := kafka.NewConsumer(config)
	if err != nil {
		return fmt.Errorf("new consumer: %w", err)
	}
	defer consumer.Close()

	// set token OAUTH
	tokenValue := strings.TrimSpace(k.token.AccessToken)
	err = consumer.SetOAuthBearerToken(kafka.OAuthBearerToken{
		TokenValue: tokenValue,
		Expiration: time.Now().Add(time.Duration(k.token.ExpiresIn) * time.Second),
		Principal:  "admin",
		// Extensions: map[string]string{},
	})
	if err != nil {
		return fmt.Errorf("set token: %w", err)
	}

	// subscribe ke topic
	if err := consumer.SubscribeTopics([]string{k.setting.Topic}, nil); err != nil {
		return fmt.Errorf("subscribe: %w", err)
	}

	fmt.Println("🚀 Kafka Consumer started — listening on topic:", k.setting.Topic)

	for {
		select {
		case <-ctx.Done():
			fmt.Println("🛑 Consumer stopped")
			return nil
		default:
			msg, err := consumer.ReadMessage(2 * time.Second)
			if err != nil {
				log.Printf("ReadMessage:%v", err)
				continue
			}
			fmt.Printf("📩 Message: %s\n", string(msg.Value))
		}
	}
}
