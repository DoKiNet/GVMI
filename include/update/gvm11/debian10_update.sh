#!/bin/bash

su gvm -c "/opt/gvm11/bin/greenbone-nvt-sync"
su gvm -c "/opt/gvm11/sbin/greenbone-certdata-sync"
su gvm -c "/opt/gvm11/sbin/greenbone-scapdata-sync"


echo ""
echo " GVM11 UPDATED"
echo ""
