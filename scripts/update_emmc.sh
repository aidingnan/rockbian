#!/bin/bash

set -e

sync

rkdeveloptool ld
rkdeveloptool db loaders/rk3328_loader_v1.16.250.bin
sleep 2
rkdeveloptool wl 0x10000 cow.img
rkdeveloptool rd
