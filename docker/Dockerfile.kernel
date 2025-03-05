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
    apt install -y make gcc gcc-aarch64-linux-gnu libncurses-dev flex bison bc libssl-dev
    # Clean up apt cache to reduce image size
    apt clean && rm -rf /var/lib/apt/lists/*
EOT

# Define build-time arguments UID and GID, default values are 1000
ARG UID=1000
ARG GID=1000

# Create a user group and user named 'builder' with the specified UID and GID
RUN groupadd -g $GID builder && \
    useradd -m -u $UID -g builder builder

# Switch to the 'builder' user for subsequent commands
USER builder
