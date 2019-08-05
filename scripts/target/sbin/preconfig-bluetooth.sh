#!/bin/bash

HCI0=/sys/kernel/debug/bluetooth/hci0

if [ -e $HCI0 ]; then
  # 0.625ms, 100 - 200
  echo 160 > $HCI0/adv_min_interval
  echo 320 > $HCI0/adv_max_interval

  # 1.25ms 20 - 40
  echo 16 > $HCI0/conn_min_interval
  echo 32 > $HCI0/conn_max_interval
fi
