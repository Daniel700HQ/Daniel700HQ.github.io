#!/bin/bash

# Ruta al archivo sources.list
SOURCES_LIST="/etc/apt/sources.list"

# Agregar repositorios de Debian 12 Bookworm para actualizaciones y seguridad
echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free" | grep -qxF "deb http://deb.debian.org/debian/ bookworm main contrib non-free" || echo "deb http://deb.debian.org/debian/ bookworm main contrib non-free" >> $SOURCES_LIST
echo "deb-src http://deb.debian.org/debian/ bookworm main contrib non-free" | grep -qxF "deb-src http://deb.debian.org/debian/ bookworm main contrib non-free" || echo "deb-src http://deb.debian.org/debian/ bookworm main contrib non-free" >> $SOURCES_LIST
echo "deb http://deb.debian.org/debian-security/ bookworm-security main contrib non-free" | grep -qxF "deb http://deb.debian.org/debian-security/ bookworm-security main contrib non-free" || echo "deb http://deb.debian.org/debian-security/ bookworm-security main contrib non-free" >> $SOURCES_LIST
echo "deb-src http://deb.debian.org/debian-security/ bookworm-security main contrib non-free" | grep -qxF "deb-src http://deb.debian.org/debian-security/ bookworm-security main contrib non-free" || echo "deb-src http://deb.debian.org/debian-security/ bookworm-security main contrib non-free" >> $SOURCES_LIST
echo "deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free" | grep -qxF "deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free" || echo "deb http://deb.debian.org/debian/ bookworm-updates main contrib non-free" >> $SOURCES_LIST
echo "deb-src http://deb.debian.org/debian/ bookworm-updates main contrib non-free" | grep -qxF "deb-src http://deb.debian.org/debian/ bookworm-updates main contrib non-free" || echo "deb-src http://deb.debian.org/debian/ bookworm-updates main contrib non-free" >> $SOURCES_LIST

# Actualizar los repositorios
apt update

echo "Repositorios de Debian 12 Bookworm (actualizaciones y seguridad) agregados correctamente."
