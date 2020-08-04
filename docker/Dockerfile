FROM debian:bullseye

WORKDIR /opt

COPY envs envs

COPY guests guests

COPY qemu qemu

COPY scripts scripts

RUN chmod +x qemu/x86_64-softmmu/qemu-system-x86_64

RUN apt-get -qy update && \
	apt-get -qy \
		-o "Dpkg::Options::=--force-confdef" \
		-o "Dpkg::Options::=--force-confold" upgrade && \
	apt-get -qy autoclean && \
	apt-get -qy install aptitude && \
	aptitude -q -y -f install \
		bridge-utils \
		cloud-image-utils \
		git \
		htop \
		libaio-dev \
		libglib2.0-0 \
		libglib2.0-dev \
		libguestfs-tools \
		liblzo2-dev \
		libpixman-1-dev \
		libpmem-dev \
		libvirt-dev \
		libvirt0 \
		lshw \
		openssh-server \
		procps \
		python3 \
		python3-pip \
		ssh \
		time \
		vim

RUN ln -s /usr/bin/python3.8 /usr/bin/python

RUN pip install cijoe

# Setup SSH
RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
RUN systemctl enable ssh
RUN service ssh restart
RUN mkdir -p /root/.ssh
RUN chmod 0700 /root/.ssh
RUN ssh-keygen -b 2048 -t rsa -f /root/.ssh/id_rsa -q -N ""
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

# Don't want any of that hastle
RUN echo "Host *" >> /root/.ssh/config
RUN echo "  StrictHostKeyChecking no" >> /root/.ssh/config
RUN echo "  NoHostAuthenticationForLocalhost yes" >> /root/.ssh/config
RUN echo "  UserKnownHostsFile=/dev/null" >> /root/.ssh/config
RUN chmod 0400 /root/.ssh/config

# Add the ssh-pub-key to the cloud-config of the emujoe qemu-guest
RUN echo "ssh_authorized_keys:" >> /opt/guests/emujoe/user-data
RUN echo -n "- " >> /opt/guests/emujoe/user-data
RUN cat /root/.ssh/id_rsa.pub >> /opt/guests/emujoe/user-data

CMD ["bash"]
