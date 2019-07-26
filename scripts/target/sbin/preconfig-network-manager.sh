#!/bin/bash

set -e

# nm-connections -> nm-connections.0 or nm-connections.eng
# nm-connections.0/
# nm-connections.eng/

DATA_DIR=/run/cowroot/root/data

# re-create eng dir, remove symlink
mkdir -p $DATA_DIR/nm-connections.0
rm -rf $DATA_DIR/nm-connections.eng
mkdir -p $DATA_DIR/nm-connections.eng
rm -rf $DATA_DIR/nm-connections
sync

# symlink 
if [ -f $DATA_DIR/root/engineering ]; then
  ln -s nm-connections.eng $DATA_DIR/nm-connections
else
  ln -s nm-connections.0 $DATA_DIR/nm-connections
fi

USN=$(cat $DATA_DIR/init/usn)

D3=${USN:0:2}
[[ "${USN:2:1}" = 0 ]] && D4=${USN:3:1} || D4=${USN:2:2}

FILE=$DATA_DIR/nm-connections/usb0.nmconnection

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

