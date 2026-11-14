#!/system/bin/sh
# Apply saved settings after boot, then keep them applied (Auto Override)
MODDIR=${0%/*}
CT_MODDIR=$MODDIR
export CT_MODDIR

until [ "$(getprop sys.boot_completed)" = "1" ]; do
  sleep 2
done
sleep 10

. "$MODDIR/lib.sh"

# Boot: what is on screen = what was saved
load_saved
apply_all
save_live

# SurfaceFlinger sometimes resets on the first unlock, so apply once more
sleep 20
load_live
apply_all

# Auto Override: every 15 s, put back whatever is currently on screen
# (saved settings, or an unsaved preview) in case the ROM or another
# color filter overwrote it. The toggle is read every loop, so the WebUI
# switch takes effect without a reboot.
while true; do
  sleep 15
  load_live
  [ "$AUTO" -eq 1 ] && apply_all
done
