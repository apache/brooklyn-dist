FROM openjdk:8-jre-alpine
LABEL maintainer="Brooklyn Team :: https://brooklyn.apache.org/"
EXPOSE 8081 8443

ARG DIST_TAR_GZ
COPY ${DIST_TAR_GZ} brooklyn.tar.gz
ENV EXTRA_JAVA_OPTS="-XX:SoftRefLRUPolicyMSPerMB=1 -Djava.security.egd=file:/dev/./urandom"

RUN apk --no-cache add bash ; \
    mkdir brooklyn ; \
    tar xvzf brooklyn.tar.gz -C /brooklyn --strip-components 1 ;

ENTRYPOINT ["/brooklyn/bin/brooklyn"]
CMD ["launch"]
