#!/bin/bash

# ===========================
# Variables de Configuración
# ===========================
WG_INTERFACE="wg0"
WG_PORT=51820
WG_SERVER_PRIVATE_KEY=$(wg genkey)
WG_SERVER_PUBLIC_KEY=$(echo "$WG_SERVER_PRIVATE_KEY" | wg pubkey)
WG_CLIENT_PRIVATE_KEY=$(wg genkey)
WG_CLIENT_PUBLIC_KEY=$(echo "$WG_CLIENT_PRIVATE_KEY" | wg pubkey)
WG_CLIENT_IP="10.0.0.2"
WG_SUBNET="10.0.0.0/24"
WG_CONFIG_PATH="/etc/wireguard/$WG_INTERFACE.conf"
WG_QR_PATH="/root/wg_client_qr.png"

# ===========================
# Comprobación de permisos
# ===========================
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root." >&2
    exit 1
fi

# ===========================
# Agregar repositorios de Debian Bookworm
# ===========================
echo "Agregando repositorios de Debian Bookworm..."
cat > /etc/apt/sources.list <<EOF
# Repositorios principales de Debian Bookworm
deb http://deb.debian.org/debian/ bookworm main contrib non-free
deb-src http://deb.debian.org/debian/ bookworm main contrib non-free

# Actualizaciones de seguridad
deb http://security.debian.org/debian-security bookworm-security main contrib non-free
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free

# Actualizaciones de Debian Bookworm
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free
deb-src http://deb.debian.org/debian/ bookworm-updates main contrib non-free
EOF

# Actualizar el índice de paquetes
apt update

# ===========================
# Instalación de Paquetes Necesarios
# ===========================
echo "Instalando paquetes necesarios..."
apt install -y xfce4 xfce4-goodies firefox-esr wireguard qrencode iptables iproute2 network-manager network-manager-gnome ristretto

# ===========================
# Configuración de WireGuard
# ===========================
echo "Configurando WireGuard..."

# Determinar la IP pública y local del servidor
SERVER_PUBLIC_IP=$(curl -s ifconfig.me || echo "0.0.0.0")
SERVER_LOCAL_IP=$(hostname -I | awk '{print $1}')

if [[ -z "$SERVER_PUBLIC_IP" || "$SERVER_PUBLIC_IP" == "0.0.0.0" ]]; then
    echo "Error: No se pudo obtener la IP pública. Configure manualmente WG_SERVER_PUBLIC_IP."
    exit 1
fi

# Crear archivo de configuración de WireGuard
cat > "$WG_CONFIG_PATH" <<EOF
[Interface]
Address = $WG_SUBNET
ListenPort = $WG_PORT
PrivateKey = $WG_SERVER_PRIVATE_KEY
PostUp = iptables -A FORWARD -i $WG_INTERFACE -o eth0 -j ACCEPT; iptables -A FORWARD -i eth0 -o $WG_INTERFACE -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i $WG_INTERFACE -o eth0 -j ACCEPT; iptables -D FORWARD -i eth0 -o $WG_INTERFACE -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = $WG_CLIENT_PUBLIC_KEY
AllowedIPs = $WG_CLIENT_IP/32
EOF

# Habilitar y reiniciar WireGuard
systemctl enable wg-quick@$WG_INTERFACE
systemctl restart wg-quick@$WG_INTERFACE

# Verificar errores de WireGuard
if ! systemctl is-active --quiet wg-quick@$WG_INTERFACE; then
    echo "Error: WireGuard no se está ejecutando correctamente. Verifique $WG_CONFIG_PATH."
    exit 1
fi

# ===========================
# Configuración del cliente
# ===========================
echo "Generando configuración y QR para el cliente..."
WG_CLIENT_CONFIG="[Interface]
PrivateKey = $WG_CLIENT_PRIVATE_KEY
Address = $WG_CLIENT_IP/32
DNS = 1.1.1.1

[Peer]
PublicKey = $WG_SERVER_PUBLIC_KEY
Endpoint = $SERVER_PUBLIC_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0"

echo "$WG_CLIENT_CONFIG" > /root/wg_client.conf

# Generar código QR
qrencode -o "$WG_QR_PATH" <<< "$WG_CLIENT_CONFIG"

# ===========================
# Comprobación de visor de imágenes
# ===========================
echo "Instalando visor de imágenes si es necesario..."
if ! command -v ristretto &>/dev/null; then
    apt install -y ristretto || apt install -y gpicview
fi

# Abrir QR generado
ristretto "$WG_QR_PATH" || gpicview "$WG_QR_PATH"

# ===========================
# Configuración completa
# ===========================
echo "Instalación y configuración completadas."
echo "Archivo de configuración del cliente: /root/wg_client.conf"
echo "Código QR generado: $WG_QR_PATH"
