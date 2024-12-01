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
apt update && apt upgrade -y

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

# Instalar los paquetes necesarios
echo "Instalando los paquetes requeridos..."
apt install -y \
    xfce4 \
    xfce4-goodies \
    lightdm \
    firefox-esr \
    iptables \
    iptables-persistent \
    gnome-themes-extra \
    network-manager \
    network-manager-gnome \
    wireguard \
    wireguard-tools \
    qrencode

# Habilitar y arrancar lightdm
echo "Habilitando LightDM para iniciar la sesión gráfica..."
systemctl enable lightdm
systemctl start lightdm

# Configuración de WireGuard

# Crear directorio para configuraciones de WireGuard
mkdir -p /etc/wireguard

# Generar las claves privadas y públicas para el servidor
echo "Generando claves para el servidor WireGuard..."
wg genkey | tee /etc/wireguard/server.key | wg pubkey > /etc/wireguard/server.pub

# Obtener la dirección IP local
LOCAL_IP=$(hostname -I | awk '{print $1}')

# Crear la configuración del servidor WireGuard
echo "Creando archivo de configuración de WireGuard para el servidor..."
cat <<EOF > /etc/wireguard/wg0.conf
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $(cat /etc/wireguard/server.key)

# Habilitar el reenvío de IPs (por si el servidor actúa como gateway)
PostUp = sysctl -w net.ipv4.ip_forward=1; iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = sysctl -w net.ipv4.ip_forward=0; iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32
EOF

# Configuración del peer (cliente)

# Generar las claves para el cliente
echo "Generando claves para el cliente WireGuard..."
wg genkey | tee /etc/wireguard/client.key | wg pubkey > /etc/wireguard/client.pub

# Dirección IP del cliente
CLIENT_IP="10.0.0.2"

# Obtener la clave pública del servidor
SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server.pub)

# Crear el archivo de configuración para el cliente (peer)
echo "Creando archivo de configuración para el cliente..."
cat <<EOF > /etc/wireguard/client.conf
[Interface]
PrivateKey = $(cat /etc/wireguard/client.key)
Address = $CLIENT_IP/32

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $LOCAL_IP:51820
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

# Generar el código QR para el cliente
echo "Generando el código QR para el cliente..."
qrencode -t png < /etc/wireguard/client.conf > /home/$USERNAME/wireguard-client.png

# Asegurarse de que los permisos estén bien configurados
chown $USERNAME:$USERNAME /home/$USERNAME/wireguard-client.png
chmod 600 /home/$USERNAME/wireguard-client.png

# Habilitar y arrancar el servicio WireGuard en el servidor
echo "Habilitando y arrancando WireGuard..."
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Finalización
echo "Instalación completada. El servidor WireGuard está configurado y el archivo QR se ha generado para el cliente en /home/$USERNAME/wireguard-client.png."

exit 0
