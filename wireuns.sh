#!/bin/bash

# Comprobamos si los paquetes necesarios están instalados
PACKAGES="iptables iproute2 dnsmasq"
for pkg in $PACKAGES; do
    if ! dpkg -l | grep -q $pkg; then
        echo "El paquete $pkg no está instalado. Instalando..."
        apt update && apt install -y $PACKAGES
    fi
done

# Restaurar la configuración de iptables a su estado original (sin NAT ni reglas específicas)
iptables -t nat -F
iptables -F
iptables -X

# Deshabilitar el reenvío de IP
echo 0 > /proc/sys/net/ipv4/ip_forward

# Eliminar las reglas guardadas
rm -f /etc/iptables/rules.v4

echo "El sistema ha sido restaurado a su configuración original."
