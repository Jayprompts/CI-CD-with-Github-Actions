# Assignment 3 - CI/CD with GitHub Actions
#
# Lightweight Alpine-based image wrapping app/app.sh. Only the packages the
# CLI actually needs are installed.

FROM alpine:3.20

RUN apk add --no-cache \
        bash \
        coreutils \
        iputils

COPY app/ /app/

RUN chmod +x /app/app.sh

WORKDIR /app

ENTRYPOINT ["/app/app.sh"]
CMD ["help"]