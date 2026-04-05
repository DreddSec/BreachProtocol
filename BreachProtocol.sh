#/bin/bash

# Make the directory
machine_name="$1"
target="$2"

trap_c(){
	echo -e "\n[!!!] Leaving the program...\n"
	exit 1
}

trap trap_c SIGINT

makedir(){
	if [ -z "$machine_name" ]; then
		echo  -e "\n[!] Must provide a name for the main directory.."
		exit 1
	fi

	if mkdir -p "$machine_name"/{scan,exploits,content}; then
    		echo -e "\n[+] Directories created successfully in: $machine_name"
		sleep 1
	else
    		echo -e "\n[-] Error: Failed to create directories."
    	exit 1
	fi
}

# Connecting to the vpn
conn(){
	local DOWNLOADS_DIR="$HOME/Downloads"

    	# 1. Comprobar si hay archivos .ovpn
    	if [[ ! $(ls "$DOWNLOADS_DIR"/*.ovpn 2>/dev/null) ]]; then
        	echo -e "\n[!] No se encontraron archivos .ovpn en $DOWNLOADS_DIR"
        	return 1
    	fi

    	echo -e "\n[?] Archivos VPN encontrados: "
    
    	# 2. Crear menú de selección
    	PS3="[?] Choose one .ovpn file: "

   	 # Listamos solo los .ovpn de la carpeta
    	select ovpn_file in "$DOWNLOADS_DIR"/*.ovpn; do
        	if [[ -n "$ovpn_file" ]]; then
            		OVPN_PATH="$ovpn_file"
            		break
        	else
            		echo "[!] Opción no válida."
        	fi
    	done
	if [[ -z "$OVPN_PATH" || ! -f "$OVPN_PATH" ]]; then
		echo -e "\n[!] Error: The .ovpn file does not exist"
		exit 1
	fi

	echo -e "\nConnecting to the vpn server.."
	sudo openvpn --config "$OVPN_PATH" --daemon --verb 1
	sleep 10
	if [ $? -eq 0 ] && [ -d /sys/class/net/tun0 ]; then
		echo -e "\n[+] Connection successfully established.."
	else
		echo -e "\n[!] Error: The connection with the server cannot be established"
		sudo pkill openvpn
		exit 1
	fi
}

# Initial scanning stealth and then use nmap for the open ports
scan(){
	if [ -z "$target" ]; then
		echo "[!] Must need an IP address.."
		exit 1
	fi
	echo -e  "\nStarting scanning on target: $target"
	for port in {1..65535}; do
		(timeout 1 bash -c "echo > /dev/tcp/$target/$port" 2>/dev/null && echo "[+] Open port $port") &
		echo "$port" >> open_ports.txt
	done; wait
	echo -e "\n[*] Extracted finded ports to a file.."
	sleep 1
	echo -e "\n[*] Parsing ports to nmap.."
	PORTS=$(tr '\n' ',' < open_ports.txt | sed 's/,$//')
	sudo nmap '-sV' '-p' "$PORTS" '-vvv' '--min-rate 3000' '--max-retries 2' '-oA' '$machine_name/nmap/allPorts'
	echo -e "\n[*] Creating visual report file.."
	if ! command -v xsltproc &> /dev/null; then
		echo -e "\n[!] Error making the visual html file of the scan"
		echo "[!?] You can install with: apt install xsltproc"
		echo -e "\n Even you can visualize the report on the $machine_name/nmap/ \n"
	fi
	xsltproc '$machine_name/nmap/allPorts.xml' -o 'report.html'
	echo -e "\n[+] Successfully created.."
	echo -e "\n Enjoy the game hax0r ;)"
}

main(){
	echo -e "\n[*] Starting the proccess..."
	makedir && conn && scan && echo -e "\n Proccess completed" || {
		echo -e "[!] Oops.. Unexpected error"
		exit 1
	}
}

main
