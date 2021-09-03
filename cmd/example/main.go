package main

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/Home24/GoService-Template/internal/pkg/app"
	"github.com/Home24/GoService-Template/internal/pkg/logging"
	"github.com/newrelic/go-agent/v3/integrations/nrlogrus"
	"github.com/newrelic/go-agent/v3/newrelic"
	"github.com/sirupsen/logrus"
)

func main() {
	version := getEnv("VERSION", "unknown")
	logger := logrus.New()
	logger.SetFormatter(logging.NewVersionedNewRelicFormatter(version))

	nrApp, err := configureNewRelic(logger)
	if err != nil {
		logger.WithError(err).Warn("Unable to configure New Relic")
	}

	port, err := strconv.Atoi(getEnv("HTTP_PORT", "80"))
	if err != nil {
		logger.WithError(err).Fatal("Unable to parse HTTP_PORT env var value")
	}

	app.Run(port, nrApp, logger)
}

func getEnv(name string, defaultValue string) string {
	if value, found := os.LookupEnv(name); found {
		return value
	}

	return defaultValue
}

func configureNewRelic(logger *logrus.Logger) (*newrelic.Application, error) {
	newRelicWaitTime, err := time.ParseDuration(getEnv("NEW_RELIC_WAIT_TIME", "2s"))
	if err != nil {
		return nil, fmt.Errorf("unable to parse New Relic wait time: %w", err)
	}

	app, err := newrelic.NewApplication(
		newrelic.ConfigAppName(getEnv("NEW_RELIC_APP_NAME", "")),
		newrelic.ConfigLicense(getEnv("NEW_RELIC_LICENSE_KEY", "")),

		func(config *newrelic.Config) {
			config.SpanEvents.Enabled = true
			config.DistributedTracer.Enabled = true
			config.Logger = nrlogrus.Transform(logger)
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed in newrelic.NewApplication: %w", err)
	}

	// Temporarily blocking call to make Distributed tracing and entity.guid available
	if err := app.WaitForConnection(newRelicWaitTime); nil != err {
		return nil, fmt.Errorf("connection to NewRelic timeout: %w", err)
	}

	return app, nil
}
