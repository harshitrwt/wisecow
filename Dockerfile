FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        bash \
        netcat-openbsd \
        fortune-mod \
        cowsay && \
    rm -rf /var/lib/apt/lists/*

# Adding cowsay/fortune to PATH else not working in my environment
ENV PATH="/usr/games:${PATH}"

WORKDIR /app

COPY wisecow.sh .

RUN chmod +x wisecow.sh

EXPOSE 4499

ENTRYPOINT ["./wisecow.sh"]

