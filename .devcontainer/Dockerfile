FROM ubuntu:22.04

# Install core dependencies
RUN apt-get update && apt-get install -y \
    curl git unzip xz-utils zip libglu1-mesa \
    ca-certificates gnupg lsb-release \
    && apt-get clean

# Install Devbox non-interactively
RUN curl -fsSL https://get.jetpack.io/devbox | bash -s -- -f && \
    echo 'source ~/.devbox/profile' >> /root/.bashrc


# Ensure devbox is available in container sessions
ENV PATH="/root/.devbox/bin:$PATH"

# Pre-create devbox environment
WORKDIR /workspace
COPY devbox.json ./
RUN devbox install

CMD [ "bash" ]