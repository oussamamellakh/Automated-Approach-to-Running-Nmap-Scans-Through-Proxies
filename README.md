# Automated Approach to Running Nmap Scans Through Proxies
# Nmap Proxy Chain Script

This repository contains a script that allows you to run Nmap scans using SOCKS5 proxies, with support for static, dynamic (Tor), and chained proxy methods. The script integrates with ProxyChains for routing network traffic through multiple proxies.

## Prerequisites

- A list of SOCKS5 proxies.
- `proxychains` and `nmap` installed on your machine.
- Tor installed for dynamic proxy (optional).

## Usage

1. Clone the repository.
2. Ensure you have a valid `socks5.txt` file with working SOCKS5 proxies.
3. Modify the script as needed.
4. Run the script with:

   ```bash
   ./script.sh
