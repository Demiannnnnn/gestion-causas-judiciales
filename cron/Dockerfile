FROM alpine:3.18

RUN apk add --no-cache curl

# Crear usuario no privilegiado
RUN adduser -D -u 1000 appuser
USER appuser

COPY crontab /etc/crontabs/root

CMD ["crond", "-f"]
