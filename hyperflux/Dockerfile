ARG SOURCE_IMG
ARG KUSTOMIZE_IMG
ARG HELM_IMG
ARG NOTIFICATION_IMG
ARG IMAGE_AUTOMATION_IMG
ARG IMAGE_REFLECTOR_IMG

FROM --platform=$TARGETPLATFORM $SOURCE_IMG AS source-controller
FROM --platform=$TARGETPLATFORM $KUSTOMIZE_IMG AS kustomize-controller
FROM --platform=$TARGETPLATFORM $HELM_IMG AS helm-controller
FROM --platform=$TARGETPLATFORM $NOTIFICATION_IMG AS notification-controller
FROM --platform=$TARGETPLATFORM $IMAGE_AUTOMATION_IMG AS image-automation-controller
FROM --platform=$TARGETPLATFORM $IMAGE_REFLECTOR_IMG AS image-reflector-controller

FROM --platform=$TARGETPLATFORM registry.access.redhat.com/ubi8/ubi:8.5 AS ubi-base

ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT

RUN curl -fsSL --output /sbin/tini https://github.com/krallin/tini/releases/download/v0.19.0/tini-${TARGETARCH}

WORKDIR /rpms
RUN curl -fsSL --output /rpms/libssh2.rpm https://download-ib01.fedoraproject.org/pub/epel/8/Everything/$(uname -m)/Packages/l/libssh2-1.9.0-5.el8.$(uname -m).rpm

# RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
# RUN yum install -y yum-utils


# RUN yumdownloader glibc zlib openssl-libs libssh2
# RUN ls -al *.rpm

RUN groupadd controller && \
    useradd --gid controller --shell /bin/sh --create-home controller

COPY --from=source-controller           /usr/local/bin/source-controller           /flux-controllers/
COPY --from=kustomize-controller        /usr/local/bin/kustomize-controller        /flux-controllers/
COPY --from=helm-controller             /usr/local/bin/helm-controller             /flux-controllers/
COPY --from=notification-controller     /usr/local/bin/notification-controller     /flux-controllers/
COPY --from=image-automation-controller /usr/local/bin/image-automation-controller /flux-controllers/
COPY --from=image-reflector-controller  /usr/local/bin/image-reflector-controller  /flux-controllers/

#=====================================================
# UBI-based Hyper Flux image starts here
#=====================================================
FROM --platform=$TARGETPLATFORM registry.access.redhat.com/ubi8/ubi-minimal:8.5

ARG TARGETPLATFORM
ARG TARGETARCH
ARG TARGETVARIANT

# Link repo to the GitHub Container Registry image
LABEL org.opencontainers.image.source="https://github.com/weaveworks/flux2-openshift"

LABEL name="Flux Operators for OpenShift" \
      vendor="Weaveworks Inc" \
      maintainer="Chanwit Kaewkasi <chanwit@weave.works>" \
      version="v0.24.0" \
      summary="Flux Operators for OpenShift" \
      description="Flux Operators for OpenShift"

COPY --from=ubi-base /sbin/tini /sbin/tini
COPY --from=ubi-base /rpms/libssh2.rpm /rpms/libssh2.rpm

# Copy user-related files from the base image because we don't have groupadd and useradd commands
COPY --from=ubi-base /etc/group /etc/group
COPY --from=ubi-base /etc/passwd /etc/passwd
COPY --from=ubi-base /home/controller /home/controller/

# Copy Flux complied version of libgit2 and re-link to /usr/lib64
COPY --from=source-controller /usr/local/lib/libgit2.so.1.1.1 /usr/lib64/
RUN cd /usr/lib64 && \
    ln -s libgit2.so.1.1.1 libgit2.so.1.1 && \
    ln -s libgit2.so.1.1.1 libgit2.so && \
    chmod +x /sbin/tini

# Install libssh2.so and it will be correctly configured
RUN rpm -i /rpms/libssh2.rpm && rm -rf /rpms

COPY --from=ubi-base /flux-controllers /usr/local/bin/

#=====================================================
# For debugging purpose
#=====================================================
# Confirm by ldd-ing the source-controller binary that every shared objects get loaded
# RUN ldd /usr/local/bin/source-controller           || true
#
# RUN ldd /usr/local/bin/kustomize-controller        || true
# RUN ldd /usr/local/bin/helm-controller             || true
# RUN ldd /usr/local/bin/notification-controller     || true
# RUN ldd /usr/local/bin/image-automation-controller || true
# RUN ldd /usr/local/bin/image-reflector-controller  || true

USER controller
ENTRYPOINT [ "/sbin/tini", "--", "source-controller" ]
