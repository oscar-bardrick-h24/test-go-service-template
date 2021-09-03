package app

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"

	"github.com/newrelic/go-agent/v3/newrelic"
	"github.com/sirupsen/logrus"
)

type handler struct {
	logger *logrus.Logger
}

func (h *handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	// This is an example of getting New Relic transaction
	// from context and setting its name.
	//
	// Keep in mind, that there must be a finite amount of
	// transaction names in New Relic. So in real-world
	// scenario you may not want to name them by request path.
	newrelic.FromContext(r.Context()).SetName(r.URL.Path)

	// This is an example of writing a log line with included
	// New Relic specific data like trace and span IDs.
	h.logger.WithContext(r.Context()).WithField("URI", r.URL.Path).Info("Request received")

	fmt.Fprintf(w, "Requested: %s\n", r.URL.Path)
}

// Run starts web server on specified port
func Run(port int, nrApp *newrelic.Application, logger *logrus.Logger) {
	handler := &handler{logger}
	router := http.NewServeMux()
	router.Handle(newrelic.WrapHandle(nrApp, "/", handler))

	srv := &http.Server{
		Addr:    fmt.Sprintf(":%d", port),
		Handler: router,
	}

	// See https://golang.org/pkg/net/http/#Server.Shutdown for example
	idleConnsClosed := make(chan struct{})

	go func() {
		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, syscall.SIGTERM, syscall.SIGINT)
		<-sigChan

		// We received an interrupt signal, shut down.
		if err := srv.Shutdown(context.Background()); err != nil {
			// Error from closing listeners, or context timeout:
			logger.WithError(err).Error("Error while attempting graceful shutdown")
		}

		close(idleConnsClosed)
	}()

	logger.WithField("Port", port).Info("Starting web server")

	if err := srv.ListenAndServe(); errors.Is(err, http.ErrServerClosed) {
		// Error starting or closing listener:
		logger.WithError(err).Error("HTTP server start/close error")
	}

	<-idleConnsClosed
}
