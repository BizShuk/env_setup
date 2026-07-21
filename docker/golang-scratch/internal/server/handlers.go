package server

import (
	"net/http"

	"golang-scratch/internal/version"
)

func NewMux() *http.ServeMux {
	mux := http.NewServeMux()
	mux.HandleFunc("GET /", Hello)
	mux.HandleFunc("GET /healthz", Healthz)
	return mux
}

func Hello(w http.ResponseWriter, r *http.Request) {
	_, _ = w.Write([]byte(version.String() + "\n"))
}

func Healthz(w http.ResponseWriter, r *http.Request) {
	_, _ = w.Write([]byte("ok\n"))
}
