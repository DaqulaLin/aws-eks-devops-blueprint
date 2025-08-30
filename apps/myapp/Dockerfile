# build
FROM golang:1.22 AS builder
WORKDIR /src

COPY go.mod ./
RUN go mod download


COPY . .
RUN go mod tidy
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /out/myapp



# runtime
FROM gcr.io/distroless/base-debian12
COPY --from=builder /out/myapp /myapp
EXPOSE 8080
USER 65532:65532
ENTRYPOINT ["/myapp"]
