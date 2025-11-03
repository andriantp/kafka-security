package main

import (
	"context"
	"fmt"
	"kafka-security/kafka"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"strings"
)

func main() {
	_, b, _, _ := runtime.Caller(0)
	basepath := filepath.Dir(b)
	base := basepath[0:strings.LastIndex(basepath, "kafka")]
	path := filepath.Join(base, "docker/certs")
	log.Printf("path:%s", path)

	// TLS
	// setting := kafka.Setting{
	// 	Path:    path,
	// 	Broker:  "localhost:9093",
	// 	Topic:   "ssl-test",
	// 	GroupID: "group-1",
	// }

	//  SASL
	// setting := kafka.Setting{
	// 	Path:    path,
	// 	Broker:  "localhost:9094", // SASL_PLAINTEXT
	// 	Topic:   "sasl-test",
	// 	GroupID: "group-1",

	// 	Username: "test",
	// 	Password: "test-secret",
	// }

	// TLS+SASL
	// setting := kafka.Setting{
	// 	Path:    path,
	// 	Broker:  "localhost:9096", //SASL + TLS
	// 	Topic:   "sasl-test",
	// 	GroupID: "group-1",

	// 	Username: "test",
	// 	Password: "test-secret",
	// }

	// scram
	setting := kafka.Setting{
		Path:    path,
		Broker:  "localhost:9096",
		Topic:   "scram-test",
		GroupID: "group-1",

		Username: "scram-user",
		Password: "scram-secret",
	}

	if len(os.Args) < 2 {
		panic("Usage: go run . [producer|consumer]")
	}

	ctx := context.Background()
	repo, err := kafka.NewKafka(setting)
	if err != nil {
		log.Fatalf("NewKafka:%v", err)
	}

	switch os.Args[1] {
	case "producer":
		// msg := "hello via TLS"
		// msg := "hello via SASL"
		// msg := "hello via TLS+SASL"
		msg := "hello via SASL_SSL (SCRAM)"
		if err := repo.Producer(ctx, msg); err != nil {
			log.Fatalf("Producer:%v", err)
		}
		fmt.Printf("✅ message sent over [%s]\n", msg)

	case "consumer":
		if err := repo.Consumer(ctx); err != nil {
			log.Fatalf("Consumer:%v", err)
		}

	default:
		panic("Unknown command: use producer or consumer")
	}
}
