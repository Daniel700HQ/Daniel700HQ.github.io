cd /etc/wireguard
umask 077
wg genkey | tee 00_server_clave_privada | wg pubkey > 00_server_clave_publica
wg genkey | tee 01_client_clave_privada | wg pubkey > 01_client_clave_publica
ls -lh

echo "[Interface]" >> wg0.conf
echo "Privatekey = $(cat /etc/wireguard/00_server_clave_privada)" >> wg0.conf
echo "Address = 10.0.0.1/24" >> wg0.conf
echo "PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE" >> wg0.conf
echo "PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth1 -j MASQUERADE" >> wg0.conf
echo "ListenPort = 51820" >> wg0.conf

echo "[Peer]" >> wg0.conf
echo "PublicKey = $(cat /etc/wireguard/01_server_clave_publica)" >> wg0.conf
echo "AllowedIPs = 10.0.0.2/32" >> wg0.conf

wg-quick up wg0
systemctl enable wg-quick@wg0

sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
