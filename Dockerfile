FROM alpine

RUN apk update && apk add --no-cache openssl

RUN mkdir /root/ca && \
    cd /root/ca && \
    mkdir certs crl newcerts private && \
    chmod 700 private && \
    touch index.txt && \
    echo 1000 > serial

RUN mkdir /root/ca/intermediate && \
    cd /root/ca/intermediate && \
    mkdir certs crl csr newcerts private && \
    chmod 700 private && \
    touch index.txt && \
    echo 1000 > serial && \
    echo 1000 > crlnumber

ADD openssl.cnf /root/ca/openssl.cnf
ADD intermediate-openssl.cnf /root/ca/intermediate/openssl.cnf

ADD openssl-wrapper.sh /root/openssl-wrapper.sh
RUN chmod 755 /root/openssl-wrapper.sh

WORKDIR /root/ca

ENTRYPOINT ["../openssl-wrapper.sh"]
