FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt update && apt install -y \
    gdb \
    vim \
    git \
    sudo \
    python3-pip \
    python3.10 \
    locales \
    && rm -rf /var/lib/apt/lists/*

ENV DEBIAN_FRONTEND=
ENV USER=user
ENV HOME=/home/$USER

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8 
ENV PYTHONIOENCODING=UTF-8 

RUN useradd -u 1000 --create-home $USER
RUN git clone https://github.com/pwndbg/pwndbg $HOME/pwndbg && cd $HOME/pwndbg && ./setup.sh


WORKDIR $HOME
USER $USER

