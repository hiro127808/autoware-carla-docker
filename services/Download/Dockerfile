FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. 基礎ツールのインストール（python3-ansible を使えばapt一発で確実に入ります）
RUN apt-get update && apt-get install -y \
    git \
    git-lfs \
    curl \
    sudo \
    python3-pip \
    ansible \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /shared/autoware/Download
ENTRYPOINT [ "/shared/Download/EntryPoint_Download.sh" ]
