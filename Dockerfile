FROM ubuntu:20.04
LABEL maintainer="Jaime Arias <arias@lipn.univ-paris13.fr>"

ENV DOCKER_RUNNING=true

# Install python 3.13
RUN apt update
RUN apt install software-properties-common -y
RUN add-apt-repository ppa:deadsnakes/ppa && apt update
RUN apt install python3.13 -y
RUN apt install python3.13-venv -y
RUN python3.13 -m ensurepip --upgrade

COPY ./server /server

# install server requirements
RUN python3.13 -m pip install -r /server/requirements.txt

# Copying files for build imitator
COPY . /imitator/

# Compiling imitator
RUN cd /imitator && bash .github/scripts/build.sh && rm -rf .github

# Change the working directory
WORKDIR /server

EXPOSE 5000
# start server

# Default command
# ENTRYPOINT [ "/imitator/bin/imitator" ]

ENTRYPOINT ["python3.13", "main.py"]
