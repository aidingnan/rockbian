# 
env_mem_addr_r=0x08000000
env_mem_size=0x1000
cow_loader_mmc_block=0xF100
loader_env_dirty="false"
loader_op="none"

#
setenv update_loader_env 'setenv loader_l ${system_l}; setenv loader_r ${system_r}; loader_env_dirty=true'
setenv rollback_loader_env 'setenv loader_r ${loader_l}; loader_env_dirty=true'
setenv zero_env_mem 'mw.b ${env_mem_addr_r} 0 ${env_mem_size}'
setenv die 'echo "sleep 30 seconds before resetting"; sleep 30; reset'

echo "start cowroot booting..."

run zero_env_mem
load ${devtype} ${devnum}:${partnum} ${env_mem_addr_r} /boot/system.env
env import -d -t ${env_mem_addr_r} - system_l system_r

if env exists system_l; then; else echo "system_l does not exist"; run die; fi
if env exists system_r; then; else echo "system_r does not exist"; run die; fi

echo "system env loaded, l: ${system_l}, r: ${system_r}"

run zero_env_mem
mmc read ${env_mem_addr_r} ${cow_loader_mmc_block} 1
env import -d -t ${env_mem_addr_r} - loader_l loader_r

if env exists loader_l; then; else setenv loader_l null; fi
if env exists loader_r; then; else setenv loader_r null; fi

echo "loader env loaded, l: ${loader_l}, r: ${loader_r}"

if test ${system_l} = ${system_r}; then
  if test "${loader_l}" = "null" && test "${loader_l}" = "null"; then
    # __|aa -> aa|aa
    echo "initialize loader env"
    loader_op="init"
    run update_loader_env
  elif test "${loader_l}" != "null" \
    && test "${loader_l}" = "${system_l}" \
    && test "${loader_r}" != "null" \
    && test "${loader_r}" = "${system_l}"; then
    echo "normal boot"
    loader_op="none"
  elif test "${loader_r}" = "$(system_l}" \
    && test "${loader_l}" != "null" \
    && test "${loader_l}" != "${system_l}"; then
    # ab|bb -> bb|bb
    echo "switched from ${loader_l} to ${loader_r}"
    run update_loader_env
    loader_op="close"
  else
    # xx|bb -> bb|bb
    echo "forcefully sync loader env"
    run update_loader_env
    loader_op="sync"
  fi
else
  if test "${loader_l}" = "null" || test "${loader_r}" = "null"; then
    echo "corrupted loader env" 
    run die
  elif test "${loader_l}" != "${loader_r}" && test "${loader_r}" = "${system_l}"; then
    # ab|bc -> bc|bc
    echo "switched from ${loader_l} to ${loader_r}, then switching to ${system_r}"
    run update_loader_env
    loader_op="double"
  elif test "${loader_l}" = "${loader_r}" && test "${loader_r}" = "${system_l}"; then
    # bb|bc -> bc|bc
    echo "switching from ${system_l} to ${system_r}"
    run update_loader_env
    loader_op="step"
  elif test "${loader_l}" = "${system_l}" && test "${loader_r}" = "${system_r}"; then
    # bc|bc -> bb|bc
    echo "failed to switch from ${system_l} to ${system_r}"
    run rollback_loader_env
    loader_op="recover"
  else
    # ??|bc 
    echo "inconsistent env states"
    run die
  fi
fi

if test "${loader_env_dirty}" = "true"; then
  run zero_env_mem
  env export -t ${env_mem_addr_r} loader_l loader_r
  mmc write ${env_mem_addr_r} ${cow_loader_mmc_block} 1
  echo "loader env saved to mmc block ${cow_loader_mmc_block}"
fi

ROOTVOL="e383f6f7-6572-46a9-a7fa-2e0633015231"
ROOT="root=UUID=${ROOTVOL}" 
ROOTFLAGS="rootflags=subvol=/vols/${loader_r} ro rootwait rootfstype=btrfs"
CONSOLE="console=tty0 console=ttyS2,1500000"
LOG="loglevel=0"
COWROOTFLAGS="cowrootflags=l=${loader_l},r=${loader_r},op=${loader_op}"

echo ${ROOT}
echo ${ROOTFLAGS}
echo ${CONSOLE}
echo ${LOG}
echo ${COWROOTFLAGS}

setenv bootargs "${ROOT} ${ROOTFLAGS} ${CONSOLE} ${LOG} ${COWROOTFLAGS}"

SUBVOL_BOOT="/vols/${loader_r}/boot"

load ${devtype} ${devnum}:${partnum} ${ramdisk_addr_r} ${SUBVOL_BOOT}/uInitrd
load ${devtype} ${devnum}:${partnum} ${kernel_addr_r} ${SUBVOL_BOOT}/Image
load ${devtype} ${devnum}:${partnum} ${fdt_addr_r} ${SUBVOL_BOOT}/dtbs/rockchip/rk3328-backus.dtb
fdt addr ${fdt_addr_r}
fdt resize 65536
booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}

# Recompile with:
# mkimage -C none -A arm -T script -d boot.cmd boot.scr
