#!/bin/bash

set -e

# assuming 0123ff05f0ceefb6ee
# atecc -b 1 -c serial

if [ $1 ]; then
  if [[ ! "$1" =~ ^0123[0-9a-f]{12}ee$ ]]; then
    echo "bad serial"
    exit 1
  fi

  # base32 alphabet

  arr=(A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 2 3 4 5 6 7)
  mask=0x1F

  x=$(( 0x${1:4:12} ))
  L6=$(( x & $mask ))

  x=$(( $x >> 5 ))
  L5=$(( x & $mask ))

  x=$(( $x >> 5 ))
  L4=$(( x & $mask ))

  x=$(( $x >> 5 ))
  L3=$(( x & $mask ))

  x=$(( $x >> 5 ))
  L2=$(( x & $mask ))

  x=$(( $x >> 5 ))
  L1=$(( x & $mask ))

  x=$(( $x >> 5 ))
  L0=$(( x & $mask ))

  x=$(( $x >> 5 ))
  H1=$(( $x % 99 + 1 ))   # [0..98] => [1..99]
  H0=$(( $x / 99 + 10 ))  # [0..8191] / 99 => [0..82] => [10..92]

  echo $(printf '%02d' $H0)$(printf '%02d' $H1)-E${arr[$L0]}${arr[$L1]}${arr[$L2]}-${arr[$L3]}${arr[$L4]}${arr[$L5]}${arr[$L6]}
 
fi
