ARG LIBRO_CLIENT_TAG
ARG LIBRO_SERVER_TAG=master

FROM registry.gitlab.com/ontola/libro:${LIBRO_CLIENT_TAG} as builder

FROM registry.gitlab.com/ontola/cache:${LIBRO_SERVER_TAG}
WORKDIR /app

COPY --from=builder /app/assets /app/assets
COPY --from=builder /app/build /app/build
COPY --from=builder /app/client_version.txt /app/client_version.txt
