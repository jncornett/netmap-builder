FROM fedora
COPY build.sh /
RUN dnf install -y make gcc
ENTRYPOINT ["/build.sh"]
