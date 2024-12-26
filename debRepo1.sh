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
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ bookworm main contrib non-free non-free-firmware

# Actualizaciones de seguridad
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware

# Actualizaciones
deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ bookworm-updates main contrib non-free non-free-firmware
EOF

# Actualizar los repositorios e instalar las actualizaciones
echo "Actualizando la lista de paquetes e instalando actualizaciones..."
apt update && apt install -y sudo xfce4 xfce4-goodies lightdm firefox-esr iptables iptables-persistent gnome-themes-extra network-manager network-manager-gnome wireguard wireguard-tools qrencode && wget https://github.com/rustdesk/rustdesk/releases/download/1.3.3/rustdesk-1.3.3-x86_64.deb && apt install ./rustdesk-1.3.3-x86_64.deb


# Preguntar si se desea crear un nuevo usuario
echo "¿Quieres crear un nuevo usuario? (s/n): "
read CREATE_USER

if [[ "$CREATE_USER" == "s" || "$CREATE_USER" == "S" ]]; then

    # Crear el usuario
    useradd -m -s /bin/bash dani

    # Asignar la contraseña al usuario
    echo "se requiere contraseña"
    passwd dani

    # Agregar al usuario a sudoers
    usermod -aG sudo "$USERNAME"
else
    echo "No se creará un nuevo usuario."
fi

# Preguntar si se desea iniciar LightDM
echo "¿Quieres iniciar LightDM automáticamente? (s/n): "
read START_LIGHTDM

if [[ "$START_LIGHTDM" == "s" || "$START_LIGHTDM" == "S" ]]; then
    echo "Habilitando LightDM para iniciar la sesión gráfica..."
    systemctl enable lightdm
    systemctl start lightdm
else
    echo "LightDM no se iniciará automáticamente."
fi


#!/bin/bash
mkdir -p /etc/wireguard
wg genkey | tee /etc/wireguard/server_private.key | wg pubkey > /etc/wireguard/server_public.key


echo [Interface] >> /etc/wireguard/wg0.conf
echo Address = 10.0.0.1/24 >> /etc/wireguard/wg0.conf
echo ListenPort = 51820 >> /etc/wireguard/wg0.conf
echo PrivateKey = $(cat "/etc/wireguard/server_private.key") >> /etc/wireguard/wg0.conf

echo "PostUp = sysctl -w net.ipv4.ip_forward=1; iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE" >> /etc/wireguard/wg0.conf
echo "PostDown = sysctl -w net.ipv4.ip_forward=0; iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE" >> /etc/wireguard/wg0.conf

#!/bin/bash
#CREAR CLIENTE  


read -p "Introduce nombre de cliente: " NOMBRECLIENTE
read -p "Introduce una IP Local wireguard que usara el cliente (ej 10.0.0.2/32) " IPCLIENTE
read -p "Cual es el ip del servidor (142.132.12.23)" SERVERIP

wg genkey | tee /etc/wireguard/$NOMBRECLIENTE-private.key | wg pubkey > /etc/wireguard/$NOMBRECLIENTE-public.key

echo [Peer] >> /etc/wireguard/wg0.conf
echo PublicKey = $(cat "/etc/wireguard/$NOMBRECLIENTE-public.key") >> /etc/wireguard/wg0.conf
echo AllowedIPs = $IPCLIENTE >> /etc/wireguard/wg0.conf


#creación del archivo conf del cliente
echo [Interface] >> /etc/wireguard/$NOMBRECLIENTE.conf
echo Address = $IPCLIENTE >> /etc/wireguard/$NOMBRECLIENTE.conf
echo PrivateKey = $(cat "/etc/wireguard/$NOMBRECLIENTE-private.key") >> /etc/wireguard/$NOMBRECLIENTE.conf
echo DNS = 1.1.1.1 >> /etc/wireguard/$NOMBRECLIENTE.conf

echo [Peer] >> /etc/wireguard/$NOMBRECLIENTE.conf
echo PublicKey = $(cat "/etc/wireguard/server_public.key") >> /etc/wireguard/$NOMBRECLIENTE.conf
echo Endpoint = $SERVERIP:51820 >> /etc/wireguard/$NOMBRECLIENTE.conf
echo AllowedIPs = 0.0.0.0/0 >> /etc/wireguard/$NOMBRECLIENTE.conf
echo PersistentKeepalive = 25 >> /etc/wireguard/$NOMBRECLIENTE.conf

#!/bin/bash
# Activar la interfaz WireGuard
wg-quick up wg0

# Configurar las reglas de iptables
iptables -A INPUT -p udp --dport 13231 -j ACCEPT
iptables -A INPUT -s 10.0.0.0/24 -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -j MASQUERADE

#!/bin/bash
# Desactivar la interfaz WireGuard
wg-quick down wg0

# Eliminar las reglas de iptables
iptables -D INPUT -p udp --dport 13231 -j ACCEPT
iptables -D INPUT -s 10.0.0.0/24 -j ACCEPT
iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -j MASQUERADE

