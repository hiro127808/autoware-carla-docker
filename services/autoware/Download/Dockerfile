FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. 基礎ツールのインストール（python3-ansible を使えばapt一発で確実に入ります）
RUN apt-get update && apt-get install -y \
    git \
    curl \
    sudo \
    python3-pip \
    ansible \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# 2. autoware リポジトリのクローン
RUN git clone https://github.com/autowarefoundation/autoware.git

WORKDIR /workspace/autoware

# 3. コレクションのインストール
RUN ansible-galaxy collection install -f -r ansible-galaxy-requirements.yaml
COPY ./EntryPoint.sh /tmp
ENTRYPOINT [ "/tmp/EntryPoint.sh" ]

