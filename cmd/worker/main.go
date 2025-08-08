package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"golang-arch/internal/bootstrap"
)

func main() {
	// Load configuration
	config, err := bootstrap.LoadConfig()
	if err != nil {
		log.Fatalf("Failed to load config: %v", err)
	}

	// Initialize dependency injection container
	container, err := bootstrap.NewContainer(config)
	if err != nil {
		log.Fatalf("Failed to create container: %v", err)
	}

	// Start the worker
	worker := bootstrap.NewWorker(container)

	// Start worker in a goroutine
	go func() {
		log.Println("Starting background worker...")
		if err := worker.Start(); err != nil {
			log.Fatalf("Failed to start worker: %v", err)
		}
	}()

	// Wait for interrupt signal to gracefully shutdown the worker
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down worker...")

	// Create a deadline for worker shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Attempt graceful shutdown
	if err := worker.Shutdown(ctx); err != nil {
		log.Fatalf("Worker forced to shutdown: %v", err)
	}

	log.Println("Worker exited")
}
