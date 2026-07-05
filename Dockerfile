# Use the official Ubuntu 26.04 as the base image
FROM ubuntu:26.04

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
    python3-setuptools \
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
    wget \
    fuse \
    qtdeclarative5-dev \
    qtbase5-dev \
    squashfs-tools && \
    rm -rf /var/lib/apt/lists/*

# Create a new user and set their home directory
RUN useradd -m -s /bin/bash fex

USER fex

WORKDIR /home/fex

# Clone the FEX repository and build it
RUN git clone --recurse-submodules https://github.com/timk1299/FEX.git --branch FEX-2607-docker && \
    cd FEX && \
    mkdir Build && \
    cd Build && \
    CC=clang CXX=clang++ cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DUSE_LINKER=lld -DENABLE_LTO=True -DBUILD_TESTING=False -DENABLE_ASSERTIONS=False -G Ninja .. && \
    ninja

WORKDIR /home/fex/FEX/Build

USER root

RUN ninja install && \
    ninja binfmt_misc

RUN useradd -m -s /bin/bash steam

RUN echo 'root:steamcmd' | chpasswd

USER steam

WORKDIR /home/steam/.fex-emu/RootFS/

# Set up rootfs

RUN wget -O Ubuntu_26_04.sqsh https://www.dropbox.com/scl/fi/1hh1ixtxxvgywovk8uc72/Ubuntu_26_04.sqsh?rlkey=c9g7j139qsffht32zhnphmh4i

RUN unsquashfs -f -d ./Ubuntu_26_04 Ubuntu_26_04.sqsh

RUN rm ./Ubuntu_26_04.sqsh

WORKDIR /home/steam/.fex-emu

RUN echo '{"Config":{"RootFS":"Ubuntu_26_04"}}' > ./Config.json

WORKDIR /home/steam/Steam

# Download and run SteamCMD
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

ENTRYPOINT ["FEXBash", "./steamcmd.sh"]
