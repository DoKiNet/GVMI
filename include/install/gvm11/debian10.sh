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
else
    exit
fi
