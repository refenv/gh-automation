FROM debian:bullseye

LABEL maintainer "os@safl.dk"

WORKDIR /root

RUN apt-get -qy update && \
	apt-get -qy \
		-o "Dpkg::Options::=--force-confdef" \
		-o "Dpkg::Options::=--force-confold" upgrade && \
	apt-get -qy autoclean

RUN apt-get -qy install \
	apt-utils \
	software-properties-common \
	sudo \
	wget

RUN apt-get -qy install \
	autoconf \
	build-essential \
	git \
	libaio-dev \
	libcunit1-dev \
	libncurses5-dev \
	libnuma-dev \
	libssl-dev \
	libtool \
	nasm \
	pkg-config \
	python3 \
	python3-pip \
	shellcheck \
	uuid-dev

RUN pip3 install meson ninja pyelftools pre-commit virtualenv==20.0.33

RUN pip3 install pre-commit

RUN pip3 install breathe Jinja2 kmdo sphinx sphinx_rtd_theme sphinxcontrib-bibtex

RUN apt-get -qy install \
	doxygen \
	exuberant-ctags \
	graphviz

RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add -

RUN add-apt-repository "deb http://apt.llvm.org/bullseye/ llvm-toolchain-bullseye-14 main"

RUN apt-get -qy update

RUN apt-get -qy install clang-format-14

RUN update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-14 100

RUN git clone https://github.com/axboe/liburing.git

RUN cd liburing && git checkout liburing-2.2 && ./configure && make && make install

CMD ["bash"]
