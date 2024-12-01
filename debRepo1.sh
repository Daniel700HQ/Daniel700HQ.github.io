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
