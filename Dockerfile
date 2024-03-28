FROM ubuntu:jammy AS base
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y software-properties-common curl git build-essential sudo && \
    apt-get clean autoclean && \
    apt-get autoremove --yes

FROM base AS extended
ARG TAGS
RUN addgroup --gid 1000 user1 \
    && adduser --gecos user1 --uid 1000 --gid 1000 --disabled-password user1 \
    && echo 'user1 ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
USER user1
WORKDIR /home/user1

FROM extended
COPY . /home/user1/workingdir
CMD ["sh", "-c", "cd /home/user1/workingdir && ./taskfile.sh private:ansible:play"]

