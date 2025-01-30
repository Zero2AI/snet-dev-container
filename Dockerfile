FROM python:3.11

# Install required dependencies
RUN apt update \
    && apt-get install -y vim git wget curl \
    && apt-get install -y libudev-dev libusb-1.0-0-dev

# Ensure shell commands use Bash
SHELL ["/bin/bash", "--login", "-c"]

# Install required Python packages
RUN pip install snet.cli

# Download and set up snetd
RUN wget https://github.com/singnet/snet-daemon/releases/download/v5.1.6/snetd-linux-amd64-v5.1.6 -O /usr/bin/snetd \
    && chmod +x /usr/bin/snetd

# Set working directory
WORKDIR /home

# Copy the setup script into the container and make it executable
COPY snetsdk.sh /home/snetsdk.sh
RUN chmod +x /home/snetsdk.sh

# Ensure the script runs correctly
CMD ["/bin/bash", "snetsdk.sh"]

#CMD /home/run-snetdservice.sh
#ENTRYPOINT ["/bin/bash", "-c"]