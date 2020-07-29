#!/bin/bash

killall openvas
killall gvmd
killall gsad
killall redis-server
killall ospd-openvas

rm /opt/gvm11/var/run/ospd-openvas.pid
rm /var/run/ospd/feed-update.lock


echo ""
echo " GVM11 STOPPED"
echo ""
