#!/bin/bash

# Function to select a random proxy from the socks5.txt file
select_random_proxy() {
    PROXY_LIST="./socks5.txt"  # Path to your socks5.txt file
    PROXY=$(shuf -n 1 "$PROXY_LIST")  # Select a random proxy
    echo "$PROXY"
}

# Function to check if a proxy is working
check_proxy() {
    local proxy=$1
    local proxy_ip=$(echo $proxy | cut -d ':' -f 1)
    local proxy_port=$(echo $proxy | cut -d ':' -f 2)
    
    # Test the proxy by sending a request through it
    if curl --silent --socks5 "$proxy_ip:$proxy_port" http://ipinfo.io; then
        echo "$proxy is working."
        return 0
    else
        echo "$proxy is not working."
        return 1
    fi
}

# Function to modify ProxyChains configuration
modify_proxychains_config() {
    local proxy=$1
    local type=$2

    # Backup original ProxyChains configuration
    cp /etc/proxychains.conf /etc/proxychains.conf.backup

    # Clear existing proxy entries before adding new ones
    sed -i '/^socks5/d' /etc/proxychains.conf

    if [ "$type" == "static" ]; then
        # Add a single proxy
        proxy_ip=$(echo $proxy | cut -d ':' -f 1)
        proxy_port=$(echo $proxy | cut -d ':' -f 2)
        echo "socks5 $proxy_ip $proxy_port" >> /etc/proxychains.conf
    elif [ "$type" == "dynamic" ]; then
        # Use Tor proxy (127.0.0.1:9050) for dynamic proxy method
        echo "socks5 127.0.0.1 9050" >> /etc/proxychains.conf  # Tor
    elif [ "$type" == "chain" ]; then
        # Use 3 random proxies and chain them together
        for i in {1..3}; do
            proxy=$(select_random_proxy)
            if check_proxy "$proxy"; then
                proxy_ip=$(echo $proxy | cut -d ':' -f 1)
                proxy_port=$(echo $proxy | cut -d ':' -f 2)
                echo "socks5 $proxy_ip $proxy_port" >> /etc/proxychains.conf
            else
                echo "Skipping proxy: $proxy due to failure."
            fi
        done
    fi
}

# Function to restore ProxyChains configuration
restore_proxychains_config() {
    cp /etc/proxychains.conf.backup /etc/proxychains.conf
    rm /etc/proxychains.conf.backup
}

# Main Script

echo "Enter target IP or domain for scan: "
read target

echo "Select proxy method: "
echo "1. Static Proxy"
echo "2. Dynamic Proxy (Tor)"
echo "3. Proxy Chain"
read -p "Enter your choice (1/2/3): " choice

case $choice in
    1)
        # Static Proxy
        proxy=$(select_random_proxy)
        if check_proxy "$proxy"; then
            modify_proxychains_config "$proxy" "static"
        else
            echo "No working proxies available for static option."
            exit 1
        fi
        ;;
    2)
        # Dynamic Proxy (Tor)
        modify_proxychains_config "127.0.0.1 9050" "dynamic"
        ;;
    3)
        # Proxy Chain
        modify_proxychains_config "$proxy" "chain"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Run Nmap scan
echo "Running Nmap scan on $target..."
proxychains nmap -sT $target

# Restore the original ProxyChains configuration
restore_proxychains_config

echo "Scan completed. ProxyChains configuration restored."
