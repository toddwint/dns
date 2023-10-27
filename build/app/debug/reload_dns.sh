#!/usr/bin/env bash
set -x
dns-add.py | tee -a /opt/"${APPNAME}"/logs/"${APPNAME}".log
service dnsmasq restart
