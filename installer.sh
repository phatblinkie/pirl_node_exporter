#!/bin/bash
if [ "$UID" != "0" ]
then
  echo your not root, please run as root for any chance of success
  exit 1
fi

useradd -m -s /bin/bash prometheus  
https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz
tar -zxvf node_exporter-0.18.1.linux-amd64.tar.gz
mv -f node_exporter-0.18.1.linux-amd64/node_exporter /usr/bin/
chmod 0755 /usr/bin/node_exporter

echo '[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/bin/node_exporter

[Install]
WantedBy=default.target

'>/etc/systemd/system/node_exporter.service

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter


firewall-cmd --zone=public --permanent --add-port=9100/tcp
firewall-cmd --reload

sysctl -w kernel.perf_event_paranoid=-1
echo "kernel.perf_event_paranoid=-1" >>/etc/sysctl.conf

