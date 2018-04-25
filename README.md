# Docker-CA

Docker CA helps create X.509 certificates for testing. On the first run, Docker CA creates a certificate authority with a root certificate and intermediate certificate. The intermediate certificate is then used to sign off on server and client certificates.

### Build

`docker build -t activecm/docker-ca:latest .`

### Usage
Docker CA uses a bind mount to persist certificate data between invocations.
You may copy the resulting certificates out of the container by referencing the
CA folder on the host system, or via `docker cp`. The server and client certificates will be located at `/root/ca/intermediate/<private | certs>/CERT_NAME.<key | cert>.pem`

Invocation: `docker run -v [--env UNSAFE_CA='true'] /host/path/to/ca/folder:/root/ca:rw docker-ca <client | server> [CERT_NAME] [DNS_NAME]`

If either `CERT_NAME` or `DNS_NAME` are not supplied, they will be prompted for.

The first parameter determines which X.509 extensions are applied to the resulting certificate.


CERT_NAME applies to the private and public key files.

Ex: `CERT_NAME`="mongodb" results in "mongodb.key.pem" and "mongodb.cert.pem"


`DNS_NAME` will be used to fill out the `CN` field of the resulting certificate and the SAN in the case of server certificates.

For use in scripts add `--env UNSAFE_CA='true'` to the container invocation. This disables key encryption and pipes output to `/dev/null`.

### Notes

All certificates produced using Docker CA will appear to be from Alice Ltd based out of Great Britain.

Root certicate DN: `/C=GB/ST=England/O=Alice Ltd/OU=Certificates/CN=root.ca.alice.fake`

Intermediate certificate DN: `/C=GB/ST=England/O=Alice Ltd/OU=Certificates/CN=inter.ca.alice.fake`

Server certificate DN's: `/C=GB/ST=England/O=Alice Ltd/OU=Servers/CN=$_DNS_NAME`

Client certificate DN's: `/C=GB/ST=England/O=Alice Ltd/OU=Clients/CN=$_DNS_NAME`
