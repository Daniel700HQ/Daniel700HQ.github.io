#!/bin/bash

# Asegúrate de ejecutar el script como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root."
    exit 1
fi

# Añadir los repositorios de Debian Bookworm (stable, updates, security)
echo "Añadiendo repositorios de Debian Bookworm..."
cat <<EOF > /etc/apt/sources.list
# Repositorios oficiales de Debian Bookworm
deb http://deb.debian.org/debian/ bookworm main contrib non-free
deb-src http://deb.debian.org/debian/ bookworm main contrib non-free

# Actualizaciones de seguridad
deb http://security.debian.org/debian-security bookworm-security main contrib non-free
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free

# Actualizaciones
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free
deb-src http://deb.debian.org/debian/ bookworm-updates main contrib non-free
EOF

# Actualizar los repositorios e instalar las actualizaciones
echo "Actualizando la lista de paquetes e instalando actualizaciones..."
apt update
apt install -y xfce4 xfce4-goodies lightdm firefox-esr iptables iptables-persistent gnome-themes-extra network-manager network-manager-gnome wireguard wireguard-tools qrencode
wget https://github.com/rustdesk/rustdesk/releases/download/1.3.3/rustdesk-1.3.3-x86_64.deb && apt install ./rustdesk-1.3.3-x86_64.deb

# Preguntar si se desea crear un nuevo usuario
echo "¿Quieres crear un nuevo usuario? (s/n): "
read CREATE_USER

if [[ "$CREATE_USER" == "s" || "$CREATE_USER" == "S" ]]; then
    # Crear un nuevo usuario
    echo "Introduce el nombre del nuevo usuario: "
    read USERNAME

    # Solicitar la contraseña del nuevo usuario
    echo "Introduce la contraseña para el usuario '$USERNAME': "
    read -s PASSWORD

    # Crear el usuario
    useradd -m -s /bin/bash "$USERNAME"

    # Asignar la contraseña al usuario
    echo "$USERNAME:$PASSWORD" | chpasswd

    # Agregar al usuario a sudoers
    usermod -aG sudo "$USERNAME"

    echo "Usuario '$USERNAME' creado con éxito."
else
    echo "No se creará un nuevo usuario."
fi

# Preguntar si se desea iniciar LightDM
echo "¿Quieres iniciar LightDM automáticamente? (s/n): "
read START_LIGHTDM

if [[ "$START_LIGHTDM" == "s" || "$START_LIGHTDM" == "S" ]]; then
    echo "Habilitando LightDM para iniciar la sesión gráfica..."
    systemctl enable lightdm
else
    echo "LightDM no se iniciará automáticamente."
fi


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
