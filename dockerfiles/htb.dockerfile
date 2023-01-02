FROM ubuntu:22.04


ENV USER=user
ENV HOME=/home/$USER

RUN useradd -u 1000 --create-home $USER

WORKDIR $HOME
USER $USER
