VER=$(grep_prop version "$MODPATH/module.prop" 2>/dev/null)
[ -n "$VER" ] || VER="v1.6.1"
MODEL=$(getprop ro.product.model)
BRAND=$(getprop ro.product.brand)

ui_print " "
ui_print "  ============================="
ui_print "   ColorTune $VER"
ui_print "   https://github.com/jawiraislop27/colortune"
ui_print "  ============================="
ui_print " "

# Root manager
if [ "$KSU" = "true" ]; then
  ui_print "- Root manager : KernelSU"
elif [ "$APATCH" = "true" ]; then
  ui_print "- Root manager : APatch (untested)"
else
  ui_print "- Root manager : Magisk (untested)"
fi
ui_print "- Device       : ${BRAND:-unknown} | ${MODEL:-}"

ui_print "- Only tested on the stock Tecno ROM with KernelSU"

# Fresh install or update
ui_print " "
if [ -f /data/adb/modules/colortune/module.prop ]; then
  ui_print "- Update detected, replacing the old version"
  [ -f /data/adb/colortune/config ] && ui_print "- Your saved settings are kept"
else
  ui_print "- Fresh install"
fi

set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/system/bin/colortune 0 2000 0755
set_perm $MODPATH/webui.sh 0 0 0755
set_perm $MODPATH/service.sh 0 0 0755

ui_print " "
ui_print "- Change settings from the WebUI or the CLI (su -c colortune)"
ui_print "- Reboot to finish the install"
ui_print " "
