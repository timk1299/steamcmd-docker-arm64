# Use the official Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y \
    git \
    cmake \
    ninja-build \
    pkgconf \
    ccache \
    clang \
    llvm \
    lld \
    binfmt-support \
    libssl-dev \
    python-setuptools \
    g++-x86-64-linux-gnu \
    libgcc-12-dev-i386-cross \
    libgcc-12-dev-amd64-cross \
    nasm \
    python3-clang \
    libstdc++-12-dev-i386-cross \
    libstdc++-12-dev-amd64-cross \
    libstdc++-12-dev-arm64-cross \
    squashfs-tools \
    squashfuse \
    libc-bin \
    libc6-dev-i386-amd64-cross \
    lib32stdc++-12-dev-amd64-cross \
    expect \
    curl \
    sudo \
    fuse \
    qtdeclarative5-dev \
    qtbase5-dev

# Create a new user and set their home directory
RUN useradd -m -s /bin/bash fex

RUN usermod -aG sudo fex

RUN echo "fex ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/fex

USER fex

WORKDIR /home/fex

# Clone the FEX repository and build it
RUN git clone --recurse-submodules https://github.com/timk1299/FEX.git --branch FEX-2512-docker && \
    cd FEX && \
    mkdir Build && \
    cd Build && \
    CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTS=False -DENABLE_ASSERTIONS=False -G Ninja .. && \
    ninja

WORKDIR /home/fex/FEX/Build

RUN sudo ninja install && \
    sudo ninja binfmt_misc

RUN sudo useradd -m -s /bin/bash steam

RUN sudo apt install wget

USER root

RUN echo 'root:steamcmd' | chpasswd

USER steam

WORKDIR /home/steam/.fex-emu/RootFS/

# Set up rootfs

RUN wget -O Ubuntu_22_04.tar.gz https://www.dropbox.com/scl/fi/16mhn3jrwvzapdw50gt20/Ubuntu_22_04.tar.gz?rlkey=4m256iahwtcijkpzcv8abn7nf

RUN tar xzf Ubuntu_22_04.tar.gz

RUN rm ./Ubuntu_22_04.tar.gz

WORKDIR /home/steam/.fex-emu

RUN echo '{"Config":{"RootFS":"Ubuntu_22_04"}}' > ./Config.json

WORKDIR /home/steam/Steam

# Download and run SteamCMD
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

ENTRYPOINT FEXBash ./steamcmd.sh
