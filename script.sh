#!/bin/bash

# Verificar permisos de root
if [ "$EUID" -ne 0 ]; then
    echo "Por favor, ejecuta este script como root."
    exit 1
fi

# Archivo de resumen
LOG_FILE="setup_summary.log"
> $LOG_FILE

# Función para preguntar al usuario
preguntar() {
    local pregunta=$1
    local respuesta
    while true; do
        read -rp "$pregunta (s/n): " respuesta
        case "$respuesta" in
            [sS]*) echo "yes" ;;
            [nN]*) echo "no" ;;
            *) echo "Respuesta inválida. Por favor, responde 's' o 'n'." ;;
        esac
        [[ "$respuesta" =~ ^[sSnN]$ ]] && break
    done
    [[ "$respuesta" =~ ^[sS]$ ]]
}

# Agregar repositorios de Debian Bookworm
if preguntar "¿Deseas agregar los repositorios de Debian Bookworm?"; then
    echo "Agregando repositorios de Debian Bookworm..." | tee -a $LOG_FILE
    echo "deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list
    echo "deb-src http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware" >> /etc/apt/sources.list
    echo "Repositorios de Bookworm agregados." | tee -a $LOG_FILE
else
    echo "Repositorios de Debian Bookworm no fueron agregados." | tee -a $LOG_FILE
fi

# Instalar XFCE
if preguntar "¿Deseas instalar XFCE?"; then
    echo "Instalando XFCE..." | tee -a $LOG_FILE
    apt update && apt install -y xfce4 xfce4-goodies lightdm network-manager-gnome
    echo "XFCE instalado correctamente." | tee -a $LOG_FILE
else
    echo "XFCE no fue instalado." | tee -a $LOG_FILE
fi

# Instalar y configurar WireGuard
if preguntar "¿Deseas instalar y configurar WireGuard?"; then
    echo "Instalando y configurando WireGuard..." | tee -a $LOG_FILE
    apt install -y wireguard qrencode iptables-persistent
    WG_DIR="/etc/wireguard"
    SERVER_CONF="$WG_DIR/wg0.conf"
    SERVER_PRIVATE_KEY=$(wg genkey)
    SERVER_PUBLIC_KEY=$(echo "$SERVER_PRIVATE_KEY" | wg pubkey)
    SERVER_PORT=51820
    SERVER_IP="10.0.0.1/24"

    mkdir -p $WG_DIR && chmod 700 $WG_DIR
    cat <<EOF > $SERVER_CONF
[Interface]
Address = $SERVER_IP
SaveConfig = true
ListenPort = $SERVER_PORT
PrivateKey = $SERVER_PRIVATE_KEY
EOF

    echo "Habilitando reenvío de paquetes..." | tee -a $LOG_FILE
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-sysctl.conf
    sysctl --system

    echo "Configurando reglas de firewall..." | tee -a $LOG_FILE
    iptables -A FORWARD -i wg0 -j ACCEPT
    iptables -A FORWARD -o wg0 -j ACCEPT
    iptables -t nat -A POSTROUTING -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE
    iptables-save > /etc/iptables/rules.v4

    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    echo "WireGuard instalado y configurado." | tee -a $LOG_FILE

    # Crear cliente WireGuard
    if preguntar "¿Deseas crear un cliente WireGuard y ver su QR?"; then
        CLIENT_NAME="cliente1"
        CLIENT_PRIVATE_KEY=$(wg genkey)
        CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
        CLIENT_IP="10.0.0.2/32"

        CLIENT_CONF="$WG_DIR/$CLIENT_NAME.conf"
        cat <<EOF > $CLIENT_CONF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP
DNS = 8.8.8.8

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $(hostname -I | awk '{print $1}'):$SERVER_PORT
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

        cat <<EOF >> $SERVER_CONF

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_IP
EOF

        systemctl restart wg-quick@wg0
        echo "Configuración del cliente generada en: $CLIENT_CONF" | tee -a $LOG_FILE
        echo "Código QR para el cliente:" | tee -a $LOG_FILE
        qrencode -t ansiutf8 < $CLIENT_CONF
    else
        echo "No se creó un cliente WireGuard." | tee -a $LOG_FILE
    fi
else
    echo "WireGuard no fue instalado ni configurado." | tee -a $LOG_FILE
fi

echo "Resumen de configuraciones guardado en $LOG_FILE"
