#!/bin/bash

# Verificar permisos de root
if [ "$EUID" -ne 0 ]; then
    echo "Por favor, ejecuta este script como root."
    exit 1
fi

# Directorio de configuración de WireGuard
WG_DIR="/etc/wireguard"
SERVER_CONF="$WG_DIR/wg0.conf"

# Función para listar clientes
listar_clientes() {
    echo "Clientes configurados:"
    grep -E "\[Peer\]" -A 2 $SERVER_CONF | grep "AllowedIPs" | awk '{print $3}' | cut -d '/' -f1
}

# Función para ver QR de un cliente
ver_qr() {
    echo "Ingrese el nombre del cliente para ver su QR:"
    read -rp "Cliente: " cliente
    CLIENT_CONF="$WG_DIR/${cliente}.conf"
    if [ -f "$CLIENT_CONF" ]; then
        qrencode -t ansiutf8 < "$CLIENT_CONF"
    else
        echo "El cliente $cliente no existe."
    fi
}

# Función para editar un cliente
editar_cliente() {
    echo "Ingrese el nombre del cliente para editar:"
    read -rp "Cliente: " cliente
    CLIENT_CONF="$WG_DIR/${cliente}.conf"
    if [ -f "$CLIENT_CONF" ]; then
        nano "$CLIENT_CONF"
        systemctl restart wg-quick@wg0
        echo "El cliente $cliente ha sido editado."
    else
        echo "El cliente $cliente no existe."
    fi
}

# Función para borrar un cliente
borrar_cliente() {
    echo "Ingrese el nombre del cliente para borrar:"
    read -rp "Cliente: " cliente
    CLIENT_CONF="$WG_DIR/${cliente}.conf"
    if [ -f "$CLIENT_CONF" ]; then
        # Eliminar del archivo de configuración del servidor
        CLIENT_PUBLIC_KEY=$(grep "PublicKey" "$CLIENT_CONF" | awk '{print $3}')
        sed -i "/\[Peer\]/,/AllowedIPs =/ { /$CLIENT_PUBLIC_KEY/d }" $SERVER_CONF
        rm -f "$CLIENT_CONF"
        systemctl restart wg-quick@wg0
        echo "El cliente $cliente ha sido eliminado."
    else
        echo "El cliente $cliente no existe."
    fi
}

# Función para borrar toda la configuración de WireGuard
borrar_todo_wireguard() {
    echo "¿Está seguro de que desea borrar toda la configuración de WireGuard? Esto eliminará todos los clientes y configuraciones. (s/n)"
    read -rp "Confirmar: " confirm
    if [[ "$confirm" =~ ^[sS]$ ]]; then
        systemctl stop wg-quick@wg0
        systemctl disable wg-quick@wg0
        rm -rf "$WG_DIR"
        # Limpiar reglas de firewall
        iptables -D FORWARD -i wg0 -j ACCEPT 2>/dev/null
        iptables -D FORWARD -o wg0 -j ACCEPT 2>/dev/null
        iptables -t nat -D POSTROUTING -o $(ip route | grep default | awk '{print $5}') -j MASQUERADE 2>/dev/null
        iptables-save > /etc/iptables/rules.v4
        # Deshabilitar reenvío de paquetes
        sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.d/99-sysctl.conf
        sysctl --system
        echo "WireGuard y todas las configuraciones han sido eliminados."
    else
        echo "Operación cancelada."
    fi
}

# Menú interactivo
while true; do
    echo "=========================================="
    echo "  Gestión de clientes de WireGuard"
    echo "=========================================="
    echo "1) Listar clientes"
    echo "2) Ver QR de un cliente"
    echo "3) Editar un cliente"
    echo "4) Borrar un cliente"
    echo "5) Borrar toda la configuración de WireGuard"
    echo "6) Salir"
    read -rp "Seleccione una opción: " opcion
    case $opcion in
        1) listar_clientes ;;
        2) ver_qr ;;
        3) editar_cliente ;;
        4) borrar_cliente ;;
        5) borrar_todo_wireguard ;;
        6) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción inválida. Por favor, elija una opción válida." ;;
    esac
done
