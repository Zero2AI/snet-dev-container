FROM python:3.11

RUN apt update \
         && apt-get install -y vim git wget curl

# Make RUN commands use \`bash --login\`:  
SHELL ["/bin/bash", "--login", "-c"]

WORKDIR /home

RUN apt-get install libudev-dev libusb-1.0-0-dev -y
#RUN pip install web3 gradio gradio_client==0.15.1 grpcio grpcio-tools

RUN pip install snet.cli

RUN wget https://github.com/singnet/snet-daemon/releases/download/v5.1.6/snetd-linux-amd64-v5.1.6 -O /usr/bin/snetd

RUN chmod +x /usr/bin/snetd

CMD rm -rf Dockerfile .devcontainer README.md .gitignore

#CMD /home/run-snetdservice.sh
#ENTRYPOINT ["/bin/bash", "-c"]