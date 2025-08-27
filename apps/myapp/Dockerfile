# build
FROM golang:1.22 AS builder
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o /out/myapp

# runtime
FROM gcr.io/distroless/base-debian12
COPY --from=builder /out/myapp /myapp
EXPOSE 8080
ENTRYPOINT ["/myapp"]
