#!/bin/bash

if [ "$#" -le 0 ]; then
    echo "Usage: ${0} <ports>"
    echo "Example: ${0} 21 22 80 443"
    exit 1
fi

ports_svc=("${@}")
hise_path="${HOME}/Hacking/hise"

if [ ! -f "${hise_path}" ]; then echo "HiddenServiceDir ${hise_path}/hidden-service" > ${hise_path}/torrc; fi

for port_svc in ${ports_svc[@]}; do
    if [[ ${port_svc} -le 1024 ]]; then port_fwd=$((port_svc + 50000)); else port_fwd=${port_svc}; fi
    if [[ ${port_fwd} -ne ${port_svc} ]]; then
        echo "[INFO] Forwarding 127.0.0.1:${port_fwd} to 127.0.0.1:${port_svc}"
        sudo iptables -t nat -I PREROUTING -p tcp --dport ${port_svc} -j REDIRECT --to-port ${port_fwd}
        sudo iptables -t nat -I OUTPUT -p tcp -o lo --dport ${port_svc} -j REDIRECT --to-port ${port_fwd}
    fi
    echo "[INFO] Enabling port ${port_svc} in the hidden service"
    echo "HiddenServicePort ${port_svc} 127.0.0.1:${port_svc}" >> ${hise_path}/torrc
done

tor -f ${hise_path}/torrc

for port_svc in ${ports_svc[@]}; do
    if [[ ${port_svc} -le 1024 ]]; then port_fwd=$((port_svc + 50000)); else port_fwd=${port_svc}; fi
    if [[ ${port_fwd} -ne ${port_svc} ]]; then
        echo "[INFO] Removing forward 127.0.0.1:${port_fwd} to 127.0.0.1:${port_svc}"
        sudo iptables -t nat -D PREROUTING -p tcp --dport ${port_svc} -j REDIRECT --to-port ${port_fwd}
        sudo iptables -t nat -D OUTPUT -p tcp -o lo --dport ${port_svc} -j REDIRECT --to-port ${port_fwd}
    fi
    echo "[INFO] Disabling port ${port_svc} in the hidden service"
    sed -i -e "/HiddenServicePort ${port_svc} 127.0.0.1:${port_svc}/d" ${hise_path}/torrc
done
