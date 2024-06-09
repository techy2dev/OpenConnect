#!/bin/bash

#Script Variables
HOST='68.168.213.74';
USER='vpnlime_wireguard';
PASS='vpnlime_wireguard';
DBNAME='vpnlime_wireguard';

timedatectl set-timezone Asia/Riyadh

install_require()
{
  clear
  echo "Updating your system."
  {
    apt-get -o Acquire::ForceIPv4=true update
  } 
  clear
  echo "Installing dependencies."
  {
    apt-get -o Acquire::ForceIPv4=true install mysql-client iptables -y
    apt-get -o Acquire::ForceIPv4=true install mariadb-server apache2 -y
    apt-get -o Acquire::ForceIPv4=true install dos2unix easy-rsa nano curl unzip jq virt-what net-tools -y
    apt-get -o Acquire::ForceIPv4=true install php-cli net-tools cron php-fpm php-json php-pdo php-zip php-gd  php-mbstring php-curl php-xml php-bcmath php-json -y
    apt-get -o Acquire::ForceIPv4=true install gnutls-bin pwgen python -y
  } 
}

install_squid(){
clear
echo 'Installing proxy.'
{
sudo cp /etc/apt/sources.list /etc/apt/sources.list_backup
echo "deb http://us.archive.ubuntu.com/ubuntu/ trusty main universe" | sudo tee --append /etc/apt/sources.list.d/trusty_sources.list > /dev/null
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 40976EAF437D05B5
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 3B4FE6ACC0B21F32    
sudo apt update
sudo apt install -y squid3=3.3.8-1ubuntu6 squid=3.3.8-1ubuntu6 squid3-common=3.3.8-1ubuntu6
wget 'http://firenetvpn.net/files/ocserv/1cBgmRVgsKFvBDGZ6d7OC2YBSQMkjYHrm' -O /etc/init.d/squid3
dos2unix /etc/init.d/squid3
sudo chmod +x /etc/init.d/squid3
sudo update-rc.d squid3 defaults
sudo update-rc.d squid3 enable
cd /etc/squid3/
rm squid.conf
echo "acl SSH dst `ip route get 8.8.8.8 | awk '/src/ {f=NR} f&&NR-1==f' RS=" "`" >> squid.conf
echo 'acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT
http_access allow SSH
http_access deny all
http_port 8080
http_port 8181
http_port 9090
coredump_dir /var/spool/squid3
refresh_pattern ^ftp: 1440 20% 10080
refresh_pattern ^gopher: 1440 0% 1440
refresh_pattern -i (/cgi-bin/|\?) 0 0% 0
refresh_pattern . 0 20% 4320
visible_hostname KobZ-Proxy
error_directory /usr/share/squid3/errors/English' >> squid.conf
cd /usr/share/squid3/errors/English
rm ERR_INVALID_URL
echo '<!--KobeKobz--><!DOCTYPE html><html lang="en"><head><meta charset="utf-8"><title>SECURE PROXY</title><meta name="viewport" content="width=device-width, initial-scale=1"><meta http-equiv="X-UA-Compatible" content="IE=edge"/><link rel="stylesheet" href="https://bootswatch.com/4/slate/bootstrap.min.css" media="screen"><link href="https://fonts.googleapis.com/css?family=Press+Start+2P" rel="stylesheet"><style>body{font-family: "Press Start 2P", cursive;}.fn-color{color: #ffff; background-image: -webkit-linear-gradient(92deg, #f35626, #feab3a); -webkit-background-clip: text; -webkit-text-fill-color: transparent; -webkit-animation: hue 5s infinite linear;}@-webkit-keyframes hue{from{-webkit-filter: hue-rotate(0deg);}to{-webkit-filter: hue-rotate(-360deg);}}</style></head><body><div class="container" style="padding-top: 50px"><div class="jumbotron"><h1 class="display-3 text-center fn-color">SECURE PROXY</h1><h4 class="text-center text-danger">SERVER</h4><p class="text-center">😍 %w 😍</p></div></div></body></html>' >> ERR_INVALID_URL
chmod 755 *
service squid3 restart
cd /etc || exit
rm /etc/apt/sources.list
sudo cp /etc/apt/sources.list_backup /etc/apt/sources.list
} 
}

install_wireguard(){
  {
MYIP=$(wget -qO- icanhazip.com);
echo -e "FIRENET DEVELOPER"
clear
apt update -y
apt install jq curl -y
DOMAIN=vpnlime.com
sub=$(</dev/urandom tr -dc a-z0-9 | head -c4)
SUB_DOMAIN=${sub}.${DOMAIN}
CF_ID=teamtextus@gmail.com
CF_KEY=ff916e57c37cacbfd224fb25fd2eab2612d47
set -euo pipefail
echo "Updating DNS for ${SUB_DOMAIN}..."
ZONE=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones?name=${DOMAIN}&status=active" \
     -H "X-Auth-Email: ${CF_ID}" \
     -H "X-Auth-Key: ${CF_KEY}" \
     -H "Content-Type: application/json" | jq -r .result[0].id)

RECORD=$(curl -sLX GET "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records?name=${SUB_DOMAIN}" \
     -H "X-Auth-Email: ${CF_ID}" \
     -H "X-Auth-Key: ${CF_KEY}" \
     -H "Content-Type: application/json" | jq -r .result[0].id)

if [[ "${#RECORD}" -le 10 ]]; then
     RECORD=$(curl -sLX POST "https://api.cloudflare.com/client/v4/zones/${ZONE}/dns_records" \
     -H "X-Auth-Email: ${CF_ID}" \
     -H "X-Auth-Key: ${CF_KEY}" \
     -H "Content-Type: application/json" \
     --data '{"type":"A","name":"'"${SUB_DOMAIN}"'","content":"'"${MYIP}"'","ttl":120,"proxied":false}' | jq -r .result.id)
fi

echo "Host : $SUB_DOMAIN"
echo "$SUB_DOMAIN" > /root/domain

# Check OS version
if [[ -e /etc/debian_version ]]; then
	source /etc/os-release
	OS=$ID # debian or ubuntu
elif [[ -e /etc/centos-release ]]; then
	source /etc/os-release
	OS=centos
fi

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[information]${Font_color_suffix}"

if [[ -e /etc/wireguard/params ]]; then
	echo -e "${Info} WireGuard sudah diinstal, silahkan ketik addwg untuk menambah client."
	exit 1
fi

echo -e "${Info} FIRENET DEVELOPER"
# Detect public IPv4 address and pre-fill for the user

# Detect public interface and pre-fill for the user
SERVER_PUB_NIC=$(ip -o -4 route show to default | awk '{print $5}');

# Install WireGuard tools and module
	if [[ $OS == 'ubuntu' ]]; then
	export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    export DEBIAN_FRONTEND=noninteractive
	apt install -y wireguard netfilter-persistent
elif [[ $OS == 'debian' ]]; then
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    export DEBIAN_FRONTEND=noninteractive
	echo "deb http://deb.debian.org/debian/ unstable main" >/etc/apt/sources.list.d/unstable.list
	printf 'Package: *\nPin: release a=unstable\nPin-Priority: 90\n' >/etc/apt/preferences.d/limit-unstable
	apt update
	apt install -y wireguard-tools iptables iptables-persistent netfilter-persistent
	apt install -y linux-headers-"$(uname -r)"
elif [[ ${OS} == 'centos' ]]; then
	curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
	yum -y update
	yum -y install wireguard-dkms wireguard-tools netfilter-persistent
	fi

chmod 600 -R /etc/wireguard/

SERVER_PRIV_KEY=$(wg genkey)
SERVER_PUB_KEY=$(echo "$SERVER_PRIV_KEY" | wg pubkey)

# Save WireGuard settings
echo "SERVER_PUB_NIC=$SERVER_PUB_NIC
SERVER_WG_NIC=wg0
SERVER_WG_IPV4=10.66.66.1
SERVER_PORT=7070
SERVER_PRIV_KEY=$SERVER_PRIV_KEY
SERVER_PUB_KEY=$SERVER_PUB_KEY" >/etc/wireguard/params

source /etc/wireguard/params

# Add server interface
echo "[Interface]
Address = $SERVER_WG_IPV4/24
ListenPort = $SERVER_PORT
PrivateKey = $SERVER_PRIV_KEY
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $SERVER_PUB_NIC -j MASQUERADE;
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $SERVER_PUB_NIC -j MASQUERADE;" >>"/etc/wireguard/wg0.conf"

iptables -t nat -I POSTROUTING -s 10.66.66.1/24 -o "$SERVER_PUB_NIC" -j MASQUERADE
iptables -I INPUT 1 -i wg0 -j ACCEPT
iptables -I FORWARD 1 -i "$SERVER_PUB_NIC" -o wg0 -j ACCEPT
iptables -I FORWARD 1 -i wg0 -o "$SERVER_PUB_NIC" -j ACCEPT
iptables -I INPUT 1 -i "$SERVER_PUB_NIC" -p udp --dport 7070 -j ACCEPT
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

sudo sysctl -w net.ipv4.ip_forward=1

systemctl enable "wg-quick@wg0"
systemctl start "wg-quick@wg0"

# Check if WireGuard is running
systemctl is-active "wg-quick@wg0"

# Tambahan
cd /usr/bin
wget -O add-wg "http://firenetvpn.net/files/repo/wg/add-wg.sh"
wget -O del-wg "http://firenetvpn.net/files/repo/wg/del-wg.sh"
wget -O cek-wg "http://firenetvpn.net/files/repo/wg/cek-wg.sh"
wget -O renew-wg "http://firenetvpn.net/files/repo/wg/renew-wg.sh"
chmod +x add-wg
chmod +x del-wg
chmod +x cek-wg
chmod +x renew-wg

cat <<\EOM >/etc/wireguard/.config.sh
#!/bin/bash
HOST='DBHOST'
USER='DBUSER'
PASS='DBPASS'
DB='DBNAME'
EOM

sed -i "s|DBHOST|$HOST|g" /etc/wireguard/.config.sh
sed -i "s|DBUSER|$USER|g" /etc/wireguard/.config.sh
sed -i "s|DBPASS|$PASS|g" /etc/wireguard/.config.sh
sed -i "s|DBNAME|$DBNAME|g" /etc/wireguard/.config.sh

  }
}

install_rclocal(){
  {
    echo "#!/bin/sh -e
service ufw stop
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent reload
sudo sysctl -w net.ipv4.ip_forward=1
service squid3 restart
service apache2 restart
systemctl restart "wg-quick@wg0"
exit 0" >> /etc/rc.local
    sudo chmod +x /etc/rc.local
    sudo systemctl enable rc-local
    sudo systemctl start rc-local.service
  }
}

install_sudo()
{
    echo -e "@@Panel123\n@@Panel123" | passwd root
}

install_done()
{
  clear
  echo "WIREGUARD INSTALLED"
  echo "IP : $(curl -s https://api.ipify.org)"
  echo
  echo
  history -c;
  rm /root/.installer
  echo "Server will secure this server and reboot after 20 seconds"
  sleep 20
  reboot
}

server_interface=$(ip route get 8.8.8.8 | awk '/dev/ {f=NR} f&&NR-1==f' RS=" ")
server_ip=$(curl -s https://api.ipify.org)

install_require
install_sudo
install_squid
install_wireguard
install_rclocal
install_done
