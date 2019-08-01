#!/bin/bash

HCI0=/sys/kernel/debug/bluetooth/hci0

if [ -e $HCI0/adv_min_interval ]; then echo 256 > $HCI0/adv_min_interval fi
if [ -e $HCI0/adv_max_interval ]; then echo 256 > $HCI0/adv_max_interval fi
