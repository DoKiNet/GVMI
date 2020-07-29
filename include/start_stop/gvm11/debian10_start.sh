#!/bin/bash

echo ""
echo " GVM11 STARTING"
echo ""

killall gvmd
killall gsad
killall redis-server


mkdir -p /run/redis-openvas/
redis-server /etc/redis/redis-openvas.conf --loglevel verbose

export PYTHONPATH=/opt/gvm11/lib/python3.7/site-packages/
export PATH=$PATH:/opt/gvm11/bin:/opt/gvm11/sbin
mkdir -p /var/run/ospd
/opt/gvm11/bin/ospd-openvas -f -u /opt/gvm11/var/run/ospd.sock --pid-file /opt/gvm11/var/run/ospd-openvas.pid --log-file /opt/gvm11/var/log/gvm/ospd-openvas.log &

chown -R gvm:gvm /opt/gvm11
chmod -R 755 /opt/gvm11
su gvm -c "/opt/gvm11/sbin/gvmd --osp-vt-update=/opt/gvm11/var/run/ospd.sock"

su gvm -c "/opt/gvm11/sbin/gsad"

echo ""
echo " GVM11 STARTED"
echo ""
