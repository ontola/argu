ARG LIBRO_CLIENT_TAG
ARG LIBRO_SERVER_TAG=master

FROM argu/libro-client:${LIBRO_CLIENT_TAG} as builder

FROM argu/libro-server:${LIBRO_SERVER_TAG}
WORKDIR /app

COPY --from=builder /app/assets /app/resources/client/
COPY --from=builder /app/build /app/resources/client/build
COPY --from=builder /app/client_version.txt /app/client_version.txt
