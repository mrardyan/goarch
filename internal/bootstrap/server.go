package bootstrap

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
)

// Server represents the HTTP server
type Server struct {
	router    *gin.Engine
	container *Container
}

// NewServer creates a new HTTP server instance
func NewServer(container *Container) *Server {
	// Set Gin mode based on environment
	gin.SetMode(gin.ReleaseMode)

	router := gin.New()

	// Add middleware
	router.Use(gin.Recovery())
	router.Use(loggerMiddleware(container.Logger))

	server := &Server{
		router:    router,
		container: container,
	}

	// Setup routes
	server.setupRoutes()

	return server
}

// setupRoutes configures all application routes
func (s *Server) setupRoutes() {
	// Health check endpoint
	s.router.GET("/health", s.healthCheck)

	// API routes
	_ = s.router.Group("/api/v1")
	{
		// Add service routes here
		// Example: userService.SetupRoutes(api)
	}
}

// healthCheck handles the health check endpoint
func (s *Server) healthCheck(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{
		"status":  "ok",
		"message": "Service is healthy",
	})
}

// ServeHTTP implements the http.Handler interface
func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	s.router.ServeHTTP(w, r)
}

// loggerMiddleware adds logging to all requests
func loggerMiddleware(logger *zap.Logger) gin.HandlerFunc {
	return gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		logger.Info("HTTP Request",
			zap.String("method", param.Method),
			zap.String("path", param.Path),
			zap.Int("status", param.StatusCode),
			zap.Duration("latency", param.Latency),
			zap.String("client_ip", param.ClientIP),
		)
		return ""
	})
}
