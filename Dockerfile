FROM linkin/ubuntu

LABEL description="学习 UEFI-ToyOS 的开发环境。"
LABEL org.opencontainers.image.authors="杨林青"

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y build-essential uuid-dev iasl nasm python-is-python3 && \
    apt-get autoremove -y; apt-get clean; rm /var/lib/apt/lists/* -r

ENTRYPOINT [ "/bin/bash" ]