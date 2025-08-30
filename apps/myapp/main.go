package main

import (
  "fmt"
  "log"
  "net/http"
  "os"
  "github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
  http.Handle("/metrics", promhttp.Handler())
  http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
    host, _ := os.Hostname()
    fmt.Fprintf(w, "hello from myapp,nice to see you! | host=%s | path=%s\n", host, r.URL.Path)
  })
  port := "8080"
  log.Printf("listening on :%s ...", port)
  log.Fatal(http.ListenAndServe(":"+port, nil))
}
