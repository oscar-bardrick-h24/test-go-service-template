package logging

import (
	"github.com/newrelic/go-agent/v3/integrations/logcontext/nrlogrusplugin"
	"github.com/sirupsen/logrus"
)

// versionedNewRelicFormatter extends New Relic formattter with a version field
type versionedNewRelicFormatter struct {
	*nrlogrusplugin.ContextFormatter
	version string
}

func (f *versionedNewRelicFormatter) Format(entry *logrus.Entry) ([]byte, error) {
	entry.Data["version"] = f.version

	return f.ContextFormatter.Format(entry)
}

// NewVersionedNewRelicFormatter returns logrus logger format for New Relic and adds version field
func NewVersionedNewRelicFormatter(version string) logrus.Formatter {
	return &versionedNewRelicFormatter{
		ContextFormatter: &nrlogrusplugin.ContextFormatter{},
		version:          version,
	}
}
