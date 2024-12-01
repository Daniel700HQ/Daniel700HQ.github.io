#!/bin/bash

# Variables de configuración (modificar según necesidades)
SERVER_PRIVATE_KEY=$(wg genkey)
SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)
SERVER_PORT=51820  # Puerto WireGuard
SERVER_IP="10.0.0.1"  # IP del servidor en la red VPN
CLIENT_IP="10.0.0.2"  # IP del cliente en la red VPN
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
INTERFACE="wg0"  # Interfaz WireGuard
EXTERNAL_IFACE="eth0"  # Interfaz con acceso a Internet
WG_CONF_DIR="/etc/wireguard"
WG_CONF="$WG_CONF_DIR/$INTERFACE.conf"
CLIENT_CONF_DIR="/etc/wireguard/clients"
IPTABLES_RULES="/etc/iptables/rules.v4"

# Comprobación de permisos de root
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root." >&2
    exit 1
fi

# Verificar si qrencode está instalado
if ! command -v qrencode &> /dev/null; then
    echo "Instalando qrencode para generar códigos QR..."
    apt update && apt install -y qrencode
fi

# Instalación de WireGuard
echo "Instalando WireGuard..."
apt update && apt install -y wireguard iptables-persistent

# Creación del directorio para configuraciones
mkdir -p "$WG_CONF_DIR"
mkdir -p "$CLIENT_CONF_DIR"

# Configuración del servidor
echo "Configurando el servidor WireGuard..."
cat > "$WG_CONF" <<EOF
[Interface]
PrivateKey = $SERVER_PRIVATE_KEY
Address = $SERVER_IP/24
ListenPort = $SERVER_PORT
PostUp = iptables -t nat -A POSTROUTING -o $EXTERNAL_IFACE -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o $EXTERNAL_IFACE -j MASQUERADE

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_IP/32
EOF

chmod 600 "$WG_CONF"

# Configuración del cliente
CLIENT_CONF="$CLIENT_CONF_DIR/client_$CLIENT_IP.conf"
echo "Creando archivo de configuración del cliente..."
cat > "$CLIENT_CONF" <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP/24

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $(curl -s ifconfig.me):$SERVER_PORT
AllowedIPs = 0.0.0.0/0, ::/0
EOF

chmod 600 "$CLIENT_CONF"

# Generar código QR
QR_CODE="$CLIENT_CONF_DIR/client_$CLIENT_IP.png"
echo "Generando código QR para la configuración del cliente..."
qrencode -o "$QR_CODE" -t png < "$CLIENT_CONF"

# Configuración de iptables
echo "Configurando iptables..."
iptables -t nat -A POSTROUTING -o $EXTERNAL_IFACE -j MASQUERADE
iptables -A FORWARD -i $EXTERNAL_IFACE -o $INTERFACE -j ACCEPT
iptables -A FORWARD -i $INTERFACE -o $EXTERNAL_IFACE -j ACCEPT

# Guardar las reglas de iptables
echo "Guardando reglas de iptables..."
iptables-save > "$IPTABLES_RULES"

# Habilitar y arrancar WireGuard
echo "Habilitando y arrancando el servicio WireGuard..."
systemctl enable wg-quick@$INTERFACE
systemctl start wg-quick@$INTERFACE

# Información final
echo "WireGuard instalado y configurado con éxito."
echo "------------------------------------------"
echo "Archivo de configuración del cliente:"
echo "Ruta absoluta: $(realpath "$CLIENT_CONF")"
echo "------------------------------------------"
echo "Código QR generado para la configuración del cliente:"
echo "Ruta absoluta: $(realpath "$QR_CODE")"
echo "------------------------------------------"
echo "Puede escanear el código QR con un celular para conectarse."
