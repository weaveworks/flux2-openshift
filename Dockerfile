FROM quay.io/operator-framework/upstream-registry-builder:v1.15.2 as builder

WORKDIR /build
COPY flux manifests/
RUN /bin/initializer -o ./bundles.db
RUN ls -la /build

FROM scratch
COPY --from=builder /build/bundles.db /bundles.db
COPY --from=builder /bin/registry-server /registry-server
COPY --from=builder /bin/grpc_health_probe /bin/grpc_health_probe
EXPOSE 50051
ENTRYPOINT ["/registry-server"]
CMD ["--database", "bundles.db"]