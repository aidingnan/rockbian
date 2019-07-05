#!/bin/bash

set -e

sync

rkdeveloptool ld
rkdeveloptool db rkbin/rk3328_loader_v1.16.250.bin
sleep 1
rkdeveloptool wl 0x00 header.img
rkdeveloptool wl 0x10000 vol.img
rkdeveloptool rd
