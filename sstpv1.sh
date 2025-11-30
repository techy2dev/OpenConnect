#!/bin/bash
# SoftEther Auto Installer Script by techy2dev

set -e

echo "=== Updating System ==="
apt update -y
apt install -y build-essential gnupg2 gcc make

echo "=== Installing SoftEther Dependencies ==="
apt install -y gcc binutils gzip libreadline-dev libssl-dev libncurses5-dev libncursesw5-dev libpthread-stubs0-dev

echo "=== Downloading SoftEther VPN Server ==="
wget https://github.com/SoftEtherVPN/SoftEtherVPN_Stable/releases/download/v4.39-9772-beta/softether-vpnserver-v4.39-9772-beta-2022.04.26-linux-x64-64bit.tar.gz -O softether.tar.gz

echo "=== Extracting SoftEther ==="
tar xvf softether.tar.gz
cd vpnserver

echo "=== Compiling SoftEther (auto-accept) ==="
yes 1 | make

echo "=== Moving vpnserver to /usr/local ==="
cd ..
mv vpnserver /usr/local/

echo "=== Setting Permissions ==="
cd /usr/local/vpnserver/
chmod 600 *
chmod 700 vpnserver
chmod 700 vpncmd

echo "=== Creating Init Script ==="
cat << 'EOF' > /etc/init.d/vpnserver
#!/bin/sh
# chkconfig: 2345 99 01
# description: SoftEther VPN Server
DAEMON=/usr/local/vpnserver/vpnserver
LOCK=/var/lock/subsys/vpnserver
test -x $DAEMON || exit 0
case "$1" in
start)
$DAEMON start
touch $LOCK
;;
stop)
$DAEMON stop
rm -f $LOCK
;;
restart)
$DAEMON stop
sleep 3
$DAEMON start
;;
*)
echo "Usage: $0 {start|stop|restart}"
exit 1
esac
exit 0
EOF

mkdir -p /var/lock/subsys
chmod 755 /etc/init.d/vpnserver

echo "=== Starting SoftEther Service ==="
/etc/init.d/vpnserver start
update-rc.d vpnserver defaults

echo "=== Auto Configuring SoftEther ==="

cd /usr/local/vpnserver

# Automated vpncmd scripting
./vpncmd localhost /SERVER /CMD ServerPasswordSet yourpassword
./vpncmd localhost /SERVER /PASSWORD:yourpassword /CMD HubCreate myhub /PASSWORD:hubpass
./vpncmd localhost /SERVER /PASSWORD:yourpassword /CMD Hub myhub
./vpncmd localhost /SERVER /PASSWORD:yourpassword /HUB:myhub /CMD SecureNatEnable
./vpncmd localhost /SERVER /PASSWORD:yourpassword /HUB:myhub /CMD UserCreate vpnuser /GROUP:none /REALNAME:none /NOTE:none
./vpncmd localhost /SERVER /PASSWORD:yourpassword /HUB:myhub /CMD UserPasswordSet vpnuser /PASSWORD:vpnpass
./vpncmd localhost /SERVER /PASSWORD:yourpassword /CMD IPsecEnable /L2TP:yes /L2TPRAW:yes /ETHERIP:yes /PSK:12345678 /DEFAULTHUB:myhub

echo "=== Configuring UFW Firewall ==="
apt install -y ufw
ufw allow 443/tcp
ufw allow 8888/tcp 
ufw allow 5555/tcp
ufw allow 992/tcp
ufw allow 1194/udp
ufw reload

echo "=== SoftEther Installation Complete ==="
echo "Server Password: yourpassword"
echo "Hub: myhub"
echo "Hub Password: hubpass"
echo "VPN User: vpnuser"
echo "VPN Password: vpnpass"
echo "PSK: 12345678"
