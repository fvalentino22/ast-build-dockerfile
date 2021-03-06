FROM docker.io/centos:latest
MAINTAINER Felix Valentino <felix@difinite.com>


RUN dnf update -y && dnf -y groupinstall "Development Tools" && \
    dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm && \
   # sed -i -e 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config && \
    dnf install -y git wget net-tools sqlite-devel psmisc ncurses-devel libtermcap-devel newt-devel libxml2-devel libtiff-devel gtk2-devel libtool libuuid-devel \
    subversion kernel-devel crontabs cronie-anacron && \
    dnf -y install https://rpmfind.net/linux/fedora/linux/releases/32/Everything/x86_64/os/Packages/l/libedit-3.1-32.20191231cvs.fc32.x86_64.rpm && \
    dnf -y install https://rpmfind.net/linux/fedora/linux/releases/32/Everything/x86_64/os/Packages/l/libedit-devel-3.1-32.20191231cvs.fc32.x86_64.rpm


#WORKDIR /usr/src/
#RUN git clone https://github.com/fvalentino22/jansson.git && \
#    git clone https://github.com/fvalentino22/pjproject.git && \
#    wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-16-current.tar.gz && \
#    wget http://github.com/fvalentino22/libsrtp/archive/2_1_x_throttle.tar.gz && \
#    tar xvfz asterisk-16-current.tar.gz && \
#    tar xf 2_1_x_throttle.tar.gz

COPY ../file-ast-dwnld/ /usr/src/

WORKDIR /usr/src/jansson
RUN autoreconf -i && /bin/sh configure --prefix=/usr/ && \
    make && make install

WORKDIR /usr/src/pjproject
RUN /bin/sh configure CFLAGS="-DNDEBUG -DPJ_HAS_IPV6=1" --prefix=/usr --libdir=/usr/lib64 --enable-shared --disable-video --disable-sound --disable-opencore-amr && \
    make dep && make && make install && ldconfig

WORKDIR /usr/src/libsrtp-2_1_x_throttle
RUN /bin/sh configure --prefix=/usr/ && make shared_library && \
    make install

WORKDIR /usr/src/asterisk-16.18.0
RUN ./contrib/scripts/install_prereq install && \
    ./configure --with-pjproject-bundled
RUN make menuselect && \
    menuselect/menuselect --enable codec_alaw \
    --enable codec_opus --enable codec_ulaw \
    --enable codec_silk --enable codec_siren7 \
    --enable codec_siren14 \
    # --enable codec_g729a \
    --enable cdr_adaptive_odbc --enable cdr_pgsql \
    --enable cdr_odbc --enable cdr_custom \
    --enable cdr_manager \
    --enable cel_custom --enable cel_manager \
    --enable cel_odbc --enable cel_pgsql \
    --enable chan_sip --enable chan_pjsip \
    --enable CORE-SOUNDS-EN-WAV \
    --enable CORE-SOUNDS-EN-ULAW \
    --enable CORE-SOUNDS-EN-ALAW \
    --enable CORE-SOUNDS-EN-GSM \
    # --enable CORE-SOUNDS-EN-G729 \
    --enable CORE-SOUNDS-EN-G722 \
    --enable CORE-SOUNDS-EN-SLN16 \
    --enable CORE-SOUNDS-EN-SIREN7 \
    --enable CORE-SOUNDS-EN-SIREN14 \
    --enable-category MENUSELECT_MOH \
    --enable EXTRA-SOUNDS-EN-WAV \
    --enable EXTRA-SOUNDS-EN-ULAW \
    --enable EXTRA-SOUNDS-EN-ALAW \
    --enable EXTRA-SOUNDS-EN-GSM \
    # --enable EXTRA-SOUNDS-EN-G729 \
    --enable EXTRA-SOUNDS-EN-G722 \
    --enable EXTRA-SOUNDS-EN-SLN16 \
    --enable EXTRA-SOUNDS-EN-SIREN7 \
    --enable EXTRA-SOUNDS-EN-SIREN14 \
    menuselect.makeopts && \
    make && make install && make samples && make config && ldconfig

CMD ["/sbin/init", "systemctl enable asterisk"]

# ENTRYPOINT ["/usr/sbin/asterisk"]

ENTRYPOINT ["/bin/bash", "-c"]
