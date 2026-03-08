#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

Custom_Config() {
    clear
    echo "---------------------------"
    echo "List of settings"
    echo "---------------------------"
    echo "1 - Anonymous crash reports"
    echo "2 - Custom DNS"
    echo "3 - IPV6"
    echo "4 - Kill switch"
    echo "5 - Moderate NAT"
    echo "6 - Netshield"
    echo "7 - Port forwarding"
    echo "8 - VPN accelerator"
    echo ""
    echo "Any other key - Config Menu"
    echo "---------------------------"
    echo ""

    read -r -p "Modifying setting : " setting

    if [ "$setting" = "1" ]; then
        read -r -p "Turn anonymous crash reports [on/off] : " crash
        protonvpn config set anonymous-crash-reports "$crash"
        sleep 2
        Custom_Config

    elif [ "$setting" = "2" ]; then
        read -r -p "Use a custom dns [on/off] : " dns
        if [ "${dns,,}" = "on" ]; then
            dnslist=()
            read -r -p "Please give your desired dns (separated by a comma for list) : " listofdns
            IFS=',' read -r -a tmp <<< "$listofdns"
            for d in "${tmp[@]}"; do
                d="${d#"${d%%[![:space:]]*}"}"
                d="${d%"${d##*[![:space:]]}"}"
                [ -n "$d" ] && dnslist+=("$d")
            done

            while true; do
                if [ "${#dnslist[@]}" -eq 0 ]; then
                    echo "No DNS entries yet."
                else
                    echo "Current DNS list:"
                    for d in "${dnslist[@]}"; do printf ' - %s\n' "$d"; done
                fi

                read -r -p "Add more DNS? [y/N]: " addmore
                case "${addmore,,}" in
                    y|yes)
                        read -r -p "Enter additional DNS (comma separated): " extra
                        IFS=',' read -r -a tmp2 <<< "$extra"
                        for d in "${tmp2[@]}"; do
                            d="${d#"${d%%[![:space:]]*}"}"
                            d="${d%"${d##*[![:space:]]}"}"
                            [ -n "$d" ] && dnslist+=("$d")
                        done
                        # dedupe while preserving order
                        declare -A __seen=()
                        uniq=()
                        for d in "${dnslist[@]}"; do
                            if [ -z "${__seen[$d]:-}" ]; then
                                uniq+=("$d")
                                __seen[$d]=1
                            fi
                        done
                        dnslist=("${uniq[@]}")
                        ;;
                    n|no|'')
                        break
                        ;;
                    *)
                        echo "Please answer y or n."
                        ;;
                esac
            done

            if [ "${#dnslist[@]}" -gt 0 ]; then
                IFS=','; dns_arg="${dnslist[*]}"; unset IFS
                protonvpn config set custom-dns on --dns "$dns_arg"
                sleep 2
                Custom_Config
            else
                echo "No valid DNS entries provided. Custom DNS not set."
                sleep 2
                Custom_Config
            fi

        elif [ "${dns,,}" = "off" ]; then
            protonvpn config set custom-dns off
            sleep 2
            Custom_Config
        else
            echo "Invalid option"
            sleep 2
            Custom_Config
        fi

    elif [ "$setting" = "3" ]; then
        read -r -p "IPV6 [on/off] : " IPV6
        protonvpn config set ipv6 "$IPV6"
        sleep 2
        Custom_Config

    elif [ "$setting" = "4" ]; then
        read -r -p "Kill Switch [standard/off] : " kill
        protonvpn config set kill-switch "$kill"
        sleep 2
        Custom_Config

    elif [ "$setting" = "5" ]; then
        read -r -p "Moderate NAT [on/off] : " NAT
        protonvpn config set moderate-nat "$NAT"
        sleep 2
        Custom_Config

    elif [ "$setting" = "6" ]; then
        read -r -p "Enable Netshield [malware-ads-trackers/malware-only/off] : " Netshield
        protonvpn config set netshield "$Netshield"
        sleep 2
        Custom_Config

    elif [ "$setting" = "7" ]; then
        read -r -p "Enable Port Forwarding [on/off] : " portforward
        protonvpn config set port-forwarding "$portforward"
        sleep 2
        Custom_Config

    elif [ "$setting" = "8" ]; then
        read -r -p "VPN accelerator [on/off] : " speed
        protonvpn config set vpn-accelerator "$speed"
        sleep 2
        Custom_Config

    else
        Config
    fi
}

Config() {
    clear
    echo "----------------------"
    echo "Config Menu"
    echo "----------------------"
    echo "1 - Privacy"
    echo "2 - P2P sharing"
    echo "3 - Gaming"
    echo "4 - Custom"
    echo ""
    echo "Any other key - Menu"
    echo "----------------------"
    echo ""

    read -r -p "Select preset: " preset

    if [ "$preset" = "1" ]; then
        protonvpn config set kill-switch standard
        protonvpn config set port-forwarding off
        protonvpn config set netshield malware-ads-trackers
        protonvpn config set anonymous-crash-reports off
        protonvpn config set vpn-accelerator on
        protonvpn config set ipv6 on
        protonvpn config set moderate-nat off

    elif [ "$preset" = "2" ]; then
        protonvpn config set kill-switch standard
        protonvpn config set port-forwarding on
        protonvpn config set netshield malware-ads-trackers
        protonvpn config set anonymous-crash-reports off
        protonvpn config set vpn-accelerator on
        protonvpn config set ipv6 on
        protonvpn config set moderate-nat off

    elif [ "$preset" = "3" ]; then
        protonvpn config set kill-switch standard
        protonvpn config set port-forwarding off
        protonvpn config set netshield malware-ads-trackers
        protonvpn config set anonymous-crash-reports off
        protonvpn config set vpn-accelerator on
        protonvpn config set ipv6 on
        protonvpn config set moderate-nat on

    elif [ "$preset" = "4" ]; then
        Custom_Config

    else
        Menu
    fi
}

Connect_loop() {
    # Location
    city="Fastest"
    country="Fastest"
    read -r -p "Random server [y/N] : " random
    if [ "${random,,}" = "n" ]; then
        read -r -p "City (leave blank for fastest) : " city
        if [ -z "$city" ]; then
            read -r -p "Country (leave blank for fastest) : " country
        fi
    fi

    # VPN settings
    settings=""
    read -r -p "P2P connection [y/N] : " P2P
    if [ "${P2P,,}" = "y" ]; then
        settings="--p2p"
    else
        read -r -p "Secure core connection [y/N] : " SC
        if [ "${SC,,}" = "y" ]; then
            settings="--securecore"
        else
            read -r -p "Tor connection [y/N] : " TOR
            if [ "${TOR,,}" = "y" ]; then
                settings="--tor"
            fi
        fi
    fi

    echo "Here are your settings :"
    echo "------------------------"
    echo "VPN settings : ${settings:-Automatic}"
    if [ "$city" = "Fastest" ] && [ "$country" = "Fastest" ]; then
        echo "City : Fastest"
        echo "Country : Fastest"
    else
        [ "$city" != "Fastest" ] && echo "City : $city"
        [ "$country" != "Fastest" ] && echo "Country : $country"
    fi
    echo ""
    read -r -p "Connect [y/N] : " vpn
    if [ "${vpn,,}" = "y" ]; then
        if [ -n "$settings" ]; then
            if [ "$city" != "Fastest" ]; then
                protonvpn connect $settings "$city"
            elif [ "$country" != "Fastest" ]; then
                protonvpn connect $settings "$country"
            else
                protonvpn connect $settings
            fi
        else
            if [ "$city" != "Fastest" ]; then
                protonvpn connect "$city"
            elif [ "$country" != "Fastest" ]; then
                protonvpn connect "$country"
            else
                protonvpn connect
            fi
        fi
        read -r -p "Press enter to continue"
    fi
}

Connection() {
    clear
    echo "----------------------"
    echo "Connection Hub"
    echo "----------------------"
    echo "1 - List of servers"
    echo "2 - Select server"
    echo ""
    echo "Any other key - Menu"
    echo "----------------------"
    echo ""

    read -r -p "Select option : " connected

    if [ "$connected" = "1" ]; then
        clear
        echo "-------------------------------"
        echo "List of servers"
        echo "-------------------------------"
        echo "1 - Countries"
        echo "2 - Cities"
        echo ""
        echo "Any other key - Connection Menu"
        echo "-------------------------------"
        echo ""

        read -r -p "Select option : " list

        if [ "$list" = "1" ]; then
            echo "List loading (Press q to leave)"
            sleep 2
            protonvpn countries
            Connection

        elif [ "$list" = "2" ]; then
            read -r -p "Choose country (country code or name) : " countrylist
            protonvpn cities --country "$countrylist"
            echo ""
            read -r -p "Press enter to continue "
            Connection

        else
            Connection
        fi

    elif [ "$connected" = "2" ]; then
        Connect_loop
    fi
}

Menu() {
    clear
    echo "----------------------"
    echo "Proton VPN - Main Menu"
    echo "----------------------"
    echo "1 - Connect"
    echo "2 - Disconnect"
    echo "3 - Config"
    echo "4 - Account"
    echo ""
    echo "Any other key - Exit"
    echo "----------------------"
    echo ""

    read -r -p "Select option : " option

    if [ "$option" = "1" ]; then
        Connection

    elif [ "$option" = "2" ]; then
        protonvpn disconnect

    elif [ "$option" = "3" ]; then
        Config

    elif [ "$option" = "4" ]; then
        clear
        echo "----------------------"
        echo "Account Hub"
        echo "----------------------"
        echo "1 - Sign in"
        echo "2 - Sign out"
        echo "3 - Account info"
        echo ""
        echo "Any other key - Menu"
        echo "----------------------"
        echo ""

        read -r -p "Select option : " account

        if [ "$account" = "1" ]; then
            read -r -p "Enter your proton email : " email
            protonvpn signin "$email" -v
            read -p "..."
            Menu

        elif [ "$account" = "2" ]; then
            protonvpn signout -v
            read -p "..."
            Menu

        elif [ "$account" = "3" ]; then
            protonvpn info
            read -p "..."
            Menu

        else
            Menu
        fi
    else
        exit
    fi
}

Menu
