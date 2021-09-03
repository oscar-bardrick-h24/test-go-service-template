package app

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/sirupsen/logrus"
)

func TestServeHTTP(t *testing.T) {
	rec := httptest.NewRecorder()

	req, err := http.NewRequest("GET", "/example", nil)
	if err != nil {
		t.Fatal(err)
	}

	h := &handler{logrus.New()}
	h.ServeHTTP(rec, req)

	if status := rec.Code; status != http.StatusOK {
		t.Errorf(
			"handler returned wrong status code: got %v want %v",
			status,
			http.StatusOK,
		)
	}

	expected := "Requested: /example\n"
	if rec.Body.String() != expected {
		t.Errorf(
			"handler returned unexpected body: got %v want %v",
			rec.Body.String(),
			expected,
		)
	}
}
