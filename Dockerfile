FROM debian:12 AS python2-build

WORKDIR /workspace
ENV TZ=Asia/Shanghai

RUN <<EOT
    sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources
    apt update
    apt install -y wget build-essential libssl-dev libncurses5-dev libncursesw5-dev libreadline-dev libsqlite3-dev libgdbm-dev libdb5.3-dev libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev libffi-dev
    apt clean && rm -rf /var/lib/apt/lists/*
EOT

RUN wget https://mirrors.ustc.edu.cn/python//2.7.18/Python-2.7.18.tar.xz
RUN tar -xf Python-2.7.18.tar.xz

RUN <<EOT
    cd Python-2.7.18
    ./configure
    make -j $(nproc)
    make altinstall
EOT

FROM debian:12

WORKDIR /workspace
ENV TZ=Asia/Shanghai

RUN <<EOT
    sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources
    apt update
    apt install -y bash-completion command-not-found git wget xz-utils
    apt install -y make gcc gcc-aarch64-linux-gnu device-tree-compiler bc libncurses-dev
    apt clean && rm -rf /var/lib/apt/lists/*
EOT

COPY --from=python2-build /usr/local/bin/python2.7 /usr/local/bin/python2.7
COPY --from=python2-build /usr/local/lib/python2.7 /usr/local/lib/python2.7
RUN ln -s /usr/local/bin/python2.7 /usr/bin/python2

RUN wget --timeout=5 --tries=3 https://releases.linaro.org/components/toolchain/binaries/6.3-2017.05/aarch64-linux-gnu/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz
RUN <<EOT
    mkdir -p ./prebuilts/gcc/linux-x86/aarch64
    tar -xf gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz -C ./prebuilts/gcc/linux-x86/aarch64
    rm gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu.tar.xz
EOT

# ./make.sh rock-2-rk3528
# ./make.sh loader
# ./make.sh itb
