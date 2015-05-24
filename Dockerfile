# Use phusion/baseimage as base image. To make your builds reproducible, make
# sure you lock down to a specific version, not to `latest`!
# See https://github.com/phusion/baseimage-docker/blob/master/Changelog.md for
# a list of version numbers.
FROM phusion/baseimage:latest

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Install updates
RUN apt-get update
RUN apt-get -y dist-upgrade

# Install OLA dependencies
RUN apt-get install -y git-core 
RUN apt-get install -y build-essential

# Download ola development files
RUN apt-get update
RUN apt-get install -y libcppunit-dev libcppunit-1.13-0 uuid-dev pkg-config libncurses5-dev libtool autoconf \
automake  g++ libmicrohttpd-dev  libmicrohttpd10 protobuf-compiler libprotobuf-lite8 python-protobuf libprotobuf-dev \
libprotoc-dev zlib1g-dev bison flex make libftdi-dev  libftdi1 libusb-1.0-0-dev liblo-dev libavahi-client-dev

WORKDIR /tmp
RUN git clone https://github.com/OpenLightingProject/ola.git ola-dev
WORKDIR /tmp/ola-dev
RUN autoreconf -i
RUN ./configure --disable-all-plugins --enable-artnet --enable-dmx4linux --enable-dummy --disable-libftdi --disable-libusb --disable-uart --disable-osc --disable-root-check
RUN make
RUN make install
RUN ldconfig

# Install avahi pieces required
RUN mkdir -p /var/run/dbus
VOLUME /var/run/dbus
RUN apt-get update -y
RUN DEBIAN_FRONTEND=noninteractive apt-get -qq install -y avahi-daemon avahi-utils \
  && apt-get -qq -y autoclean \
  && apt-get -qq -y autoremove \
  && apt-get -qq -y clean
COPY avahi-daemon.conf /etc/avahi/avahi-daemon.conf

# Setup services
RUN mkdir /etc/service/00dbus
ADD dbus-daemon.sh /etc/service/00dbus/run
RUN chmod +x /etc/service/00dbus/run

RUN mkdir /etc/service/01avahi-daemon
ADD avahi-daemon.sh /etc/service/01avahi-daemon/run
RUN chmod +x /etc/service/01avahi-daemon/run

RUN mkdir /etc/service/02olad-daemon
ADD olad-daemon.sh /etc/service/02olad-daemon/run
RUN chmod +x /etc/service/02olad-daemon/run

# Clean up APT when done.
#RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
