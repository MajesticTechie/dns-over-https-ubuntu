#!bin/bash
# Will install Cloudflared on Ubuntu and set this to be the default resolver.
# Source: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation

##################
## Installation ##
##################
#Download and install latest version
wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo apt install ./cloudflared-linux-amd64.deb

#Show Version
echo "Checking Version...."
cloudflared --version

read -n 1 -s -r -p "If version appears ok, Press any key to continue."
#Cleanup
rm -f cloudflared-linux-amd64.deb

#########################
## Start configuration ##
#########################
# Start on port 5553
cloudflared proxy-dns --port 5553

#Give time for service to start
sleep 5s # Waits 5 seconds.

#Make sure Service is running:
echo "running query to check serice is running:"
dig +short @127.0.0.1 -p5553 cloudflare.com AAAA

read -n 1 -s -r -p "If DNS appears ok, Press any key to continue."

#Setup Serice to run on Startup
sudo tee /etc/systemd/system/cloudflared-proxy-dns.service >/dev/null <<EOF
[Unit]
Description=DNS over HTTPS (DoH) proxy client
Wants=network-online.target nss-lookup.target
Before=nss-lookup.target

[Service]
AmbientCapabilities=CAP_NET_BIND_SERVICE
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
DynamicUser=yes
ExecStart=/usr/local/bin/cloudflared proxy-dns

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl enable --now cloudflared-proxy-dns

# Configure resolver:
sudo rm -f /etc/resolv.conf
echo nameserver 127.0.0.1 | sudo tee /etc/resolv.conf >/dev/null

#Final DNS check
echo "Final Check. DNS check on localhost on standard DNS port [53]"
echo "!!! Cloudflared is now running on 127.0.0.1 port 53 !!!"
dig +short @127.0.0.1 cloudflare.com AAAA
