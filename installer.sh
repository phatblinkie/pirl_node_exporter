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

#add systemd unti for node_exporter
echo '[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
ExecStart=/usr/bin/node_exporter --collector.processes --collector.systemd --collector.textfile.directory /tmp/node


[Install]
WantedBy=default.target

'>/etc/systemd/system/node_exporter.service
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

#add node stats puller locally
cat > /usr/bin/nodestats.sh << EOL
#!/bin/bash
if [ ! -e /tmp/node ]
 then
 mkdir -p /tmp/node >/dev/null
fi

echo "# HELP pirl_blocknumber The number of the most recent block" > /tmp/node/node.prom
echo "# TYPE pirl_blocknumber gauge" >> /tmp/node/node.prom
echo pirl_blocknumber \$((\`curl -m 5 --speed-time 4 -s --speed-limit 1000 -H "Content-Type: application/json" \
--data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' 127.0.0.1:6588 | \
awk -F "result\":" {'print \$2'} | sed 's/"//g'|sed 's/}//g'\`))  >> /tmp/node/node.prom

EOL
chmod 0755 /usr/bin/nodestats.sh

#add cronjob every 5 minutes
echo "*/5 * * * * /usr/bin/nodestats.sh 2>&1 >/dev/null" > /tmp/cronjob.txt
crontab -u root /tmp/cronjob.txt

firewall-cmd --zone=public --permanent --add-port=9100/tcp
firewall-cmd --reload

sysctl -w kernel.perf_event_paranoid=-1
echo "kernel.perf_event_paranoid=-1" >>/etc/sysctl.conf

