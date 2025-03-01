# -------------------
# The build container
# -------------------
FROM debian:bookworm-slim AS build

WORKDIR /root/

# Install base packages
RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install --no-install-recommends \
      build-essential \
      git \
      gnupg \
      python3-venv \
      python3-pip \
      cmake

# Add Pi repo + key
ADD http://archive.raspberrypi.org/debian/raspberrypi.gpg.key /root/raspberrypi.gpg.key

RUN echo "deb http://archive.raspberrypi.com/debian/ bookworm main" > \
      /etc/apt/sources.list.d/raspi.list && \
    apt-key add /root/raspberrypi.gpg.key

# Install libraspberrypi-dev
RUN apt-get -y update && \
    apt-get -y install --no-install-recommends \
      libraspberrypi-dev && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/F5OEO/librpitx.git /root/librpitx && \
    cd /root/librpitx/src/ && \
    make && \
    make install

COPY . /root/horusrpitx
RUN chmod +x /root/horusrpitx/start_docker.sh

RUN cd /root/horusrpitx && \
    pip install --break-system-packages -r requirements.txt && \
    cd mod && \
    make

RUN git clone https://github.com/projecthorus/horusdemodlib.git /root/horusdemodlib && \
    cd /root/horusdemodlib && mkdir build && cd build && \
    cmake .. && \
    make && \
    make install && \
    ldconfig

# Run 
ENTRYPOINT ["/root/horusrpitx/start_docker.sh"]
