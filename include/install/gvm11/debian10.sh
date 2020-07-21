#!/bin/bash

echo -e "\n GVMI - Version: $GVMI_VERSION\n"
echo -e " Greenbone Vulnerability Management Installer\n"

echo -n "Do you want to install GVM 11? (Y/n) "
read RET

if [ "$RET" == "no" ] || [ "$RET" == "NO" ] || [ "$RET" == "No" ] || \
    [ "$RET" == "n" ] || [ "$RET" == "N" ]; then
    exit
elif [ "$RET" == "yes" ] || [ "$RET" == "YES" ] || [ "$RET" == "Yes" ] || \
        [ "$RET" == "Y" ] || [ "$RET" == "y" ] || [ "$RET" == "" ]; then

        apt update

        #### BEGIN GVM-LIBS 11.0.1 ####
        mkdir -p /opt/gvm11
        mkdir -p /opt/gvm11/src
        cd /opt/gvm11/src
        wget https://github.com/greenbone/gvm-libs/archive/v11.0.1.tar.gz
        tar -xvzf v11.0.1.tar.gz
        rm v11.0.1.tar.gz
        mv gvm-libs-11.0.1 gvm-libs
        cd gvm-libs

        apt -y install cmake pkg-config libglib2.0-dev libgpgme-dev \
                        libgnutls28-dev uuid-dev libssh-gcrypt-dev \
                        libldap2-dev libhiredis-dev libxml2-dev

        export PKG_CONFIG_PATH=/opt/gvm11/lib/pkgconfig:$PKG_CONFIG_PATH
        mkdir build
        cd build
        cmake -DCMAKE_INSTALL_PREFIX=/opt/gvm11 ..
        make install
        #### END GVM-LIBS 11.0.1 ####

        #### BEGIN OPENVAS 7.0.1 ####
        cd /opt/gvm11/src
        wget https://github.com/greenbone/openvas/archive/v7.0.1.tar.gz
        tar -xvzf v7.0.1.tar.gz
        rm v7.0.1.tar.gz
        mv openvas-7.0.1 openvas
        cd /opt/gvm11/src/openvas
        apt -y install gcc pkg-config libssh-gcrypt-dev libgnutls28-dev \
                    libglib2.0-dev libpcap-dev libgpgme-dev bison \
                    libksba-dev libsnmp-dev libgcrypt20-dev wget rsync \
                    curl
        export PKG_CONFIG_PATH=/opt/gvm11/lib/pkgconfig:$PKG_CONFIG_PATH
        mkdir build
        cd build
        cmake -DCMAKE_INSTALL_PREFIX=/opt/gvm11 ..
        make install
        cat > /etc/ld.so.conf.d/gvm.conf <<EOF
/opt/gvm11/lib
EOF
        ldconfig

        useradd -r -d /opt/gvm11 -c "GVM User" -s /bin/bash gvm
        chown -R gvm:gvm /opt/gvm11
        echo "db_address = /run/redis-openvas/redis.sock" > /opt/gvm11/etc/openvas/openvas.conf

        echo -e "\n\n"
        echo -e "##########################################"
        echo -e "######### greenbone-nvt-sync #############"
        echo -e "##########################################"
        echo -e "\n\n"

        su gvm -c "/opt/gvm11/bin/greenbone-nvt-sync"
        #### END OPENVAS 7.0.1 ####

        #### BEGIN REDIS-SERVER ####
        apt install redis
        cp /opt/gvm11/src/openvas/config/redis-openvas.conf /etc/redis/
        chown redis:redis /etc/redis/redis-openvas.conf
        mkdir -p /run/redis-openvas/
        redis-server /etc/redis/redis-openvas.conf --loglevel verbose
        /opt/gvm11/sbin/openvas -u
        #### END REDIS-SERVER ####

        #### BEGIN OSPD 2.0.1 ####
        cd /opt/gvm11/src
        wget https://github.com/greenbone/ospd/archive/v2.0.1.tar.gz
        tar -xvzf v2.0.1.tar.gz
        rm v2.0.1.tar.gz
        mv ospd-2.0.1 ospd
        cd ospd
        apt -y install python3-setuptools python3-paramiko \
                    python3-defusedxml python3-lxml
        mkdir -p /opt/gvm11/lib/python3.7/site-packages
        export PYTHONPATH=/opt/gvm11/lib/python3.7/site-packages/
        python3 setup.py install --prefix=/opt/gvm11
        #### END OSPD 2.0.1 ####

        #### BEGIN OSPD-OPENVAS 1.0.1 ####
        cd /opt/gvm11/src
        wget https://github.com/greenbone/ospd-openvas/archive/v1.0.1.tar.gz
        tar -xvzf v1.0.1.tar.gz
        rm v1.0.1.tar.gz
        mv ospd-openvas-1.0.1 ospd-openvas
        cd ospd-openvas
        apt install python3-psutil
        python3 setup.py install --prefix=/opt/gvm11
        #### END OSPD-OPENVAS 1.0.1 ####

        #### BEGIN GVMD 9.0.1 ####
        cd /opt/gvm11/src
        wget https://github.com/greenbone/gvmd/archive/v9.0.1.tar.gz
        tar -xvzf v9.0.1.tar.gz
        rm v9.0.1.tar.gz
        mv gvmd-9.0.1 gvmd
        cd gvmd

        apt -y install gnutls-bin pkg-config libical-dev \
                       xml-twig-tools doxygen xmltoman \
                       xsltproc postgresql postgresql-contrib \
                       postgresql-server-dev-all
        export PKG_CONFIG_PATH=/opt/gvm11/lib/pkgconfig:$PKG_CONFIG_PATH
        mkdir build
        cd build
        cmake -DCMAKE_INSTALL_PREFIX=/opt/gvm11 ..
        make install
        /opt/gvm11/bin/gvm-manage-certs -a

        su - postgres -c "createuser gvm"
        su - postgres -c "createdb -O gvm gvmd"

        su postgres -c "psql gvmd -c 'create role dba with superuser noinherit;'"
        su postgres -c "psql gvmd -c 'grant dba to gvm;'"
        su postgres -c "psql gvmd -c 'create extension \"uuid-ossp\";'"

        chown -R gvm:gvm /opt/gvm11
        chmod -R 755 /opt/gvm11
        /opt/gvm11/sbin/greenbone-scapdata-sync
        /opt/gvm11/sbin/greenbone-certdata-sync
        su gvm -c "/opt/gvm11/sbin/gvmd --listen=127.0.0.1"
        su gvm -c "/opt/gvm11/sbin/gvmd --create-user=admin --password=live"

        apt -y install texlive-latex-extra --no-install-recommends
        apt -y install texlive-fonts-recommended xsltproc xmlstarlet \
                    zip rpm fakeroot dpkg nsis gnupg sshpass \
                    socat snmp smbclient haveged
        #### END GVMD 9.0.1 ####

        #### BEGIN IANA Services Names ####
        #BUG WITH GVMD 9.0.1, fixed in next release
        #cd /opt/gvm11/src
        #mkdir iana
        #cd iana
        #wget https://www.iana.org/assignments/service-names-port-numbers/service-names-port-numbers.xml
        #/opt/gvm11/sbin/gvm-portnames-update service-names-port-numbers.xml
        #rm service-names-port-numbers.xml
        #### END IANA Services Names ####

        #### BEGIN GSA 9.0.1 ####
        cd /opt/gvm11/src
        wget https://github.com/greenbone/gsa/archive/v9.0.1.tar.gz
        tar -xvzf v9.0.1.tar.gz
        rm v9.0.1.tar.gz
        mv gsa-9.0.1 gsa
        cd gsa
        apt -y install libmicrohttpd-dev libxml2-dev python-polib \
                       apt-transport-https

        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
        apt update
        apt -y install yarn

        export PKG_CONFIG_PATH=/opt/gvm11/lib/pkgconfig:$PKG_CONFIG_PATH
        mkdir build
        cd build
        cmake -DCMAKE_INSTALL_PREFIX=/opt/gvm11 ..
        make install

        chown -R gvm:gvm /opt/gvm11
        chmod -R 755 /opt/gvm11
        su gvm -c "/opt/gvm11/sbin/gsad"
        #### END GSA 9.0.1 ####
else
    exit
fi
