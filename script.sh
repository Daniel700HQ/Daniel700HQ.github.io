#!/bin/bash

# Verificar permisos de superusuario
if [[ $EUID -ne 0 ]]; then
    echo "Este script debe ejecutarse como root. Usa sudo." >&2
    exit 1
fi

WG_DIR="/etc/wireguard"
WG_CONF="$WG_DIR/wg0.conf"
WG_INTERFACE="wg0"
SERVER_IP_RANGE="10.0.0.1/24"
SERVER_PORT="51820"
NETWORK_INTERFACE="eth0" # Cambia esto según la interfaz de red de tu servidor.

echo "=== Creando claves públicas y privadas ==="
mkdir -p "$WG_DIR"

# Generar claves del servidor
wg genkey | tee "$WG_DIR/server_private.key" | wg pubkey > "$WG_DIR/server_public.key"

# Proteger claves privadas
chmod 600 "$WG_DIR/server_private.key"

# Leer claves generadas
SERVER_PRIVATE_KEY=$(cat "$WG_DIR/server_private.key")
SERVER_PUBLIC_KEY=$(cat "$WG_DIR/server_public.key")

echo "=== Configurando el archivo $WG_CONF ==="
cat << EOF > "$WG_CONF"
[Interface]
Address = $SERVER_IP_RANGE
SaveConfig = true
ListenPort = $SERVER_PORT
PrivateKey = $SERVER_PRIVATE_KEY

# Configuración de red
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o $NETWORK_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o $NETWORK_INTERFACE -j MASQUERADE
EOF

chmod 600 "$WG_CONF"

echo "=== Habilitando el reenvío de paquetes ==="
# Habilitar reenvío en sysctl
sysctl_conf="/etc/sysctl.conf"
if ! grep -q "net.ipv4.ip_forward=1" "$sysctl_conf"; then
    echo "net.ipv4.ip_forward=1" >> "$sysctl_conf"
fi
sysctl -p

echo "=== Iniciando y habilitando el servicio WireGuard ==="
systemctl enable wg-quick@$WG_INTERFACE
systemctl start wg-quick@$WG_INTERFACE

echo "=== Configuración completada ==="
echo "Clave privada del servidor: $SERVER_PRIVATE_KEY"
echo "Clave pública del servidor: $SERVER_PUBLIC_KEY"
echo "Archivo de configuración creado en $WG_CONF"
