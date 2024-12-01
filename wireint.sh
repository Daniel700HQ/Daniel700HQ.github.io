#!/bin/bash

# Comprobamos si los paquetes necesarios están instalados
PACKAGES="iptables iproute2 dnsmasq"
for pkg in $PACKAGES; do
    if ! dpkg -l | grep -q $pkg; then
        echo "El paquete $pkg no está instalado. Instalando..."
        apt update && apt install -y $PACKAGES
    fi
done

# Verifica si WireGuard está activo
if ! systemctl is-active --quiet wg-quick@wg0; then
    echo "WireGuard no está activo. Asegúrate de que el servicio WireGuard esté configurado y en ejecución."
    exit 1
fi

# Obtener la IP de la interfaz principal
IP_ADDR=$(ip -4 addr show dev eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -z "$IP_ADDR" ]; then
    echo "No se pudo obtener la IP de la interfaz principal."
    exit 1
fi

# Habilitar el reenvío de IP en el sistema
echo 1 > /proc/sys/net/ipv4/ip_forward

# Configurar iptables para NAT y permitir el acceso a Internet a los clientes WireGuard
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
iptables -A FORWARD -i wg0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o wg0 -j ACCEPT

# Guardar las reglas de iptables
iptables-save > /etc/iptables/rules.v4

echo "Configuración completada. Los clientes WireGuard tendrán acceso a Internet."