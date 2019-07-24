#!/bin/bash

USN=$(cat /run/cowroot/root/data/init/usn)

D3=${USN:0:2}
[[ "${USN:2:1}" = 0 ]] && D4=${USN:3:1} || D4=${USN:2:2}

FILE=/etc/NetworkManager/system-connections/usb0.nmconnection

cat > $FILE  << EOF
[connection]
id=usb0
uuid=9285a52f-6e92-4e5c-83bb-77443ceb64dd
type=ethernet
permissions=
timestamp=

[ethernet]
mac-address-blacklist=

[ipv4]
address1=169.254.${D3}.${D4}/16
dns-search=
method=manual

[ipv6]
addr-gen-mode=eui64
dns-search=
method=link-local
EOF

chmod 600 $FILE

