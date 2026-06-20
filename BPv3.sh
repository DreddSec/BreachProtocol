#!/bin/bash

machine_name=""
target=""
connect_vpn=0
disconnect_vpn=0
scan_type="tcp"

usage() {
    cat << EOF
Usage: ./bp.sh [OPTIONS]

OPTIONS:
    -f FOLDER_NAME      Folder name of the machine/target
    -h HOST/IP          IP of the target
    -c                  Connect to the VPN
    -d                  Disconnect of the VPN
    -t                  TCP scan (default)
    -u                  UDP scan
    
EXAMPLES:
    ./bp.sh -f FOLDER_NAME -h IP -c -t
    ./bp.sh -f FOLDER_NAME -h IP -u
    ./bp.sh -d

EOF
    exit 1
}

while getopts "f:h:cdtu" opt; do
    case $opt in
        f) machine_name="$OPTARG" ;;
        h) target="$OPTARG" ;;
        c) connect_vpn=1 ;;
        d) disconnect_vpn=1 ;;
        t) scan_type="tcp" ;;
        u) scan_type="udp" ;;
        *) usage ;;
    esac
done

# Crtl + C
cleanup() {
    echo -e "\n[!] Exiting. Cleaning proccess..."
    pkill -f "nmap.*$target"
    sleep 1
    exit 1
}
trap cleanup SIGINT SIGTERM

# Make directories for the assestment
makedir(){
    if [[ -z "$machine_name" ]]; then
        echo -e "\n[!] Must provide a folder name with -f [FOLDER_NAME]"
        exit 1
    fi

    if mkdir -p "$machine_name"/{scan,exploits,content}; then
    echo -e "\n[+] Directories created successfully in: $(pwd)/$machine_name"
        sleep 1
    else
        echo -e "\n[-] Error: Failed to create directories."
        exit 1
    fi
}

# Function to connect to the VPN 
conn(){
    local DOWNLOADS_DIR="$HOME/Downloads/"

    if [ -d /sys/class/net/tun0 ]; then
        echo -e "\n[+] VPN already connected (tun0 detected)."
        return 0
    fi

    if [[ ! $(ls "$DOWNLOADS_DIR"/*.ovpn 2>/dev/null) ]]; then
        echo -e "\n[!] No se encontraron archivos .ovpn en $DOWNLOADS_DIR"
        return 1
    fi

    echo -e "\n[?] Archivos VPN encontrados: "
    
    PS3="[?] Choose one .ovpn file: "
    select ovpn_file in "$DOWNLOADS_DIR"/*.ovpn; do
        if [[ -n "$ovpn_file" ]]; then
            OVPN_PATH="$ovpn_file"
            break
        else
            echo "[!] Not valid option."
        fi
    done
    
    if [[ -z "$OVPN_PATH" || ! -f "$OVPN_PATH" ]]; then
        echo -e "\n[!] Error: The .ovpn file does not exist"
        exit 1
    fi

    echo -e "\nConnecting to the vpn server.."
    sudo openvpn --config "$OVPN_PATH" --daemon --verb 1
    sleep 10
    
    if [ -d /sys/class/net/tun0 ]; then
        echo -e "\n[+] Connection successfully established.."
    else
        echo -e "\n[!] Error: The connection with the server cannot be established"
        sudo pkill openvpn
        exit 1
    fi
}

# Function to disconnecting from the VPN
disconn(){
    if [ -d /sys/class/net/tun0 ]; then
        echo -e "\n[*] Disconnecting from VPN..."
        sudo pkill openvpn
        sleep 2
        if [ ! -d /sys/class/net/tun0 ]; then
            echo -e "[+] VPN disconnected successfully."
        else
            echo -e "[-] Error disconnecting VPN."
            exit 1
        fi
    else
        echo -e "\n[!] No VPN connection found (tun0 interface not detected)."
    fi
}

# Function that scans the target between tcp or udp packets and output the results in a file report 
scan(){
    echo -e "\nStarting scanning on target: $target ($scan_type)"
    
    if [ "$scan_type" = "tcp" ]; then
        REPORT_NAME="allPorts_tcp"
        echo -e "\n[*] Running nmap scan (TCP)..."
        sudo nmap -sSV -p- -vv -Pn -n -T2 --min-rate 3000 --stats-every=5s --max-retries 3 --source-port 53 -oA "$machine_name/scan/$REPORT_NAME" "$target"
    else
        REPORT_NAME="allPorts_udp"
        echo -e "\n[*] Running nmap scan (UDP)..."
        sudo nmap -sU -p- -vv -Pn -n -T2 --min-rate 3000 --stats-every=5s --max-retries 3 --source-port 53 -oA "$machine_name/scan/$REPORT_NAME" "$target"
    fi
    
    sleep 2
    echo -e "\n[*] Creating visual report file.."
    # Checks if the tool xsltproc it's available on the machine to make the report cleaner
    if ! command -v xsltproc &> /dev/null; then
        echo -e "\n[!] Error making the visual html file of the scan"
        echo "[!?] You can install with: apt install xsltproc"
        echo -e "\n Even you can visualize the report on the $machine_name/scan/ \n"
    fi
    
    if [ -f "$machine_name/scan/${REPORT_NAME}.xml" ] && grep -q "</nmaprun>" "$machine_name/scan/${REPORT_NAME}.xml"; then
      xsltproc "$machine_name/scan/${REPORT_NAME}.xml" -o "$machine_name/scan/report_${scan_type}.html" 
      echo -e "\n[+] Report successfully created: $(pwd)/$machine_name/scan/report_${scan_type}.html"
    else
      echo "[!] XML incomplete or corrupted, report not generated"
    fi
    
    echo -e "\n✥ Enjoy the game hax0r ✥"
}

main(){
    if [ $disconnect_vpn -eq 1 ]; then
        disconn
        exit 0
    fi
    
    echo -e "\n[*] Starting the process..."
    # If everything goes right starts all the functions 
    if [ $connect_vpn -eq 1 ] && [ -n "$machine_name" ] && [ -n "$target" ]; then
        makedir && conn && scan
    elif [ -n "$machine_name" ] && [ -n "$target" ]; then
        if [ ! -d "$machine_name" ]; then
            makedir
        fi
        scan
    else
        usage
    fi
}

main
