#!/bin/bash

echo ""
echo " GVM11 STARTING"
echo ""

killall openvas
killall gvmd
killall gsad
killall redis-server
killall ospd-openvas

rm /opt/gvm11/var/run/ospd-openvas.pid
rm /var/run/ospd/feed-update.lock

mkdir -p /run/redis-openvas/
redis-server /etc/redis/redis-openvas.conf --loglevel verbose

export PYTHONPATH=/opt/gvm11/lib/python3.7/site-packages/
export PATH=$PATH:/opt/gvm11/bin:/opt/gvm11/sbin
mkdir -p /var/run/ospd
chmod -R 777 /var/run/ospd
/opt/gvm11/bin/ospd-openvas -f -u /opt/gvm11/var/run/ospd.sock \
                            --socket-mode 0o777 \
                            --pid-file /opt/gvm11/var/run/ospd-openvas.pid \
                            --log-file /opt/gvm11/var/log/gvm/ospd-openvas.log&

chown -R gvm:gvm /opt/gvm11
chmod -R 755 /opt/gvm11
su gvm -c "/opt/gvm11/sbin/gvmd --osp-vt-update=/opt/gvm11/var/run/ospd.sock"

su gvm -c "/opt/gvm11/sbin/gsad"

chmod 777 /tmp/gvm-sync-cert
chmod 777 /tmp/gvm-sync-scap

echo ""
echo " GVM11 STARTED"
echo ""
