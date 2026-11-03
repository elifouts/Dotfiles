#!/bin/bash
head -n1 /proc/stat
grep -E '^(MemTotal|MemAvailable):' /proc/meminfo
echo "UP $(cut -d' ' -f1 /proc/uptime)"
echo "KERN $(< /proc/sys/kernel/osrelease)"
echo "HOST $(< /proc/sys/kernel/hostname)"
echo "OS $(grep -m1 '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')"
echo "CPUM $(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ *//')"
for b in /sys/class/power_supply/BAT*; do
    [ -r "$b/capacity" ] && { echo "BAT $(< "$b/capacity")|$(< "$b/status")"; break; }
done
for h in /sys/class/hwmon/hwmon*; do
    if [ "$(< "$h/name")" = coretemp ]; then echo "CPUT $(< "$h/temp1_input")"; break; fi
done
command -v nvidia-smi >/dev/null && nvidia-smi \
    --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu \
    --format=csv,noheader,nounits 2>/dev/null | sed 's/^/GPU /'
exit 0
