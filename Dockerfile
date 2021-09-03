FROM alpine:3.10
COPY bin/example /usr/local/bin/example
EXPOSE 80
CMD ["/usr/local/bin/example"]
