#!/system/bin/sh
OUT=/tmp/phy110-runtime-audit.txt
{
  echo '=== identity ==='
  getprop ro.boot.prjname
  getprop ro.product.device
  getprop ro.product.model
  getprop ro.twrp.device_version
  echo '=== mounts ==='
  mount | grep -E ' /(vendor|odm|vendor_dlkm|system_dlkm|metadata|data|mnt/vendor/persist) '
  echo '=== crypto services ==='
  getprop | grep -E 'twrp.phy110.stock|init.svc.vendor.(qsee|keymint|gatekeeper|weaver)'
  echo '=== modules ==='
  cat /proc/modules | grep -E 'synaptics|qca_cld3_kiwi_v2|cnss2|adsp_loader|oplus_chg|qseecom|smcinvoke|nxp|st54'
  echo '=== input ==='
  cat /proc/bus/input/devices
  echo '=== network ==='
  ip link 2>/dev/null
  echo '=== block/filesystem ==='
  blkid /dev/block/by-name/metadata 2>/dev/null
  blkid /dev/block/by-name/userdata 2>/dev/null
  echo '=== usb/adsp ==='
  ls -l /sys/kernel/boot_adsp/boot /sys/kernel/boot_adsp/ssr 2>/dev/null
  getprop sys.usb.state
  echo '=== recovery log tail ==='
  tail -n 250 /tmp/recovery.log 2>/dev/null
} > "$OUT" 2>&1
cat "$OUT"
