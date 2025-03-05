# Use Debian 12 as the base image for building Python 2
FROM debian:12 AS python2-build

# Set the working directory to /workspace
WORKDIR /workspace

# Set the timezone to Asia/Shanghai
ENV TZ=Asia/Shanghai

# Run the following commands:
RUN <<EOT
    # Change the default Debian mirror to USTC mirror for faster download speeds in China
    sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources
    # Update the apt package list
    apt update
    # Install build tools and dependencies
    apt install -y wget build-essential libssl-dev libncurses5-dev libncursesw5-dev libreadline-dev libsqlite3-dev libgdbm-dev libdb5.3-dev libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev libffi-dev
    # Clean up apt cache to reduce image size
    apt clean && rm -rf /var/lib/apt/lists/*
EOT

# Download the Python 2.7.18 source package
RUN wget https://mirrors.ustc.edu.cn/python//2.7.18/Python-2.7.18.tar.xz

# Extract the Python 2.7.18 source package
RUN tar -xf Python-2.7.18.tar.xz

# Enter the source directory, configure, compile, and install Python 2.7.18
RUN <<EOT
    cd Python-2.7.18
    ./configure
    make -j $(nproc)
    make altinstall
EOT

# Use Debian 12 as the base image
FROM debian:12

# Set the working directory to /workspace
WORKDIR /workspace

# Set the timezone to Asia/Shanghai
ENV TZ=Asia/Shanghai

# Run the following commands:
RUN <<EOT
    # Change the default Debian mirror to USTC mirror for faster download speeds in China
    sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list.d/debian.sources
    # Update the apt package list
    apt update
    # Install common utilities
    apt install -y bash-completion command-not-found git wget xz-utils
    # Install build tools and dependencies
    apt install -y make gcc gcc-aarch64-linux-gnu device-tree-compiler bc libncurses-dev
    # Clean up apt cache to reduce image size
    apt clean && rm -rf /var/lib/apt/lists/*
EOT

# Copy Python 2.7 executable and libraries from the previous build stage to the final image
COPY --from=python2-build /usr/local/bin/python2.7 /usr/local/bin/python2.7
COPY --from=python2-build /usr/local/lib/python2.7 /usr/local/lib/python2.7

# Create a symbolic link to make `python2` available as a command
RUN ln -s /usr/local/bin/python2.7 /usr/bin/python2

# Define build-time arguments UID and GID, default values are 1000
ARG UID=1000
ARG GID=1000

# Create a user group and user named 'builder' with the specified UID and GID
RUN groupadd -g $GID builder && \
    useradd -m -u $UID -g builder builder

# Switch to the 'builder' user for subsequent commands
USER builder
