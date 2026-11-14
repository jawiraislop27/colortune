#!/system/bin/sh
# Internal helper for the ColorTune WebUI. Not meant to be run by hand.
#   pm C R G B       preview contrast + RGB color balance (not saved)
#   ps S             preview saturation (not saved)
#   save C S R G B   apply and save everything
#   reset            apply and save normal values
#   auto 0|1         Auto Override off / on
#   theme dark|light remember the WebUI theme
#   get              print what is on screen now, plus AUTO and THEME,
#                    and the saved values (SAVED=C S R G B) so the WebUI
#                    knows whether there is anything left to save

CT_MODDIR=${CT_MODDIR:-/data/adb/modules/colortune}
[ -f "$CT_MODDIR/lib.sh" ] || { echo "lib.sh missing"; exit 1; }
. "$CT_MODDIR/lib.sh"

need_int() {
  for _a in "$@"; do
    is_int "$_a" || { echo "bad value: $_a"; exit 1; }
  done
}

case "$1" in
  pm)
    need_int "$2" "$3" "$4" "$5"
    load_live
    clamp "$2" 50 200; CONTRAST=$CL
    clamp "$3" 50 100; WB_R=$CL
    clamp "$4" 50 100; WB_G=$CL
    clamp "$5" 50 100; WB_B=$CL
    apply_matrix; save_live
    ;;
  ps)
    need_int "$2"
    load_live
    clamp "$2" 0 400; SATURATION=$CL
    apply_sat; save_live
    ;;
  save)
    need_int "$2" "$3" "$4" "$5" "$6"
    load_saved
    clamp "$2" 50 200; CONTRAST=$CL
    clamp "$3" 0 400;  SATURATION=$CL
    clamp "$4" 50 100; WB_R=$CL
    clamp "$5" 50 100; WB_G=$CL
    clamp "$6" 50 100; WB_B=$CL
    apply_all; save_conf; save_live
    ;;
  reset)
    load_saved
    CONTRAST=100; SATURATION=100; WB_R=100; WB_G=100; WB_B=100
    apply_all; save_conf; save_live
    ;;
  auto)
    need_int "$2"
    load_saved
    clamp "$2" 0 1; AUTO=$CL
    save_conf
    ;;
  theme)
    load_saved
    case "$2" in
      dark|light) THEME=$2; save_conf ;;
      *) exit 1 ;;
    esac
    ;;
  get)
    load_saved
    echo "SAVED=$CONTRAST $SATURATION $WB_R $WB_G $WB_B"
    load_live
    echo "CONTRAST=$CONTRAST"
    echo "SATURATION=$SATURATION"
    echo "WB_R=$WB_R"
    echo "WB_G=$WB_G"
    echo "WB_B=$WB_B"
    echo "AUTO=$AUTO"
    echo "THEME=$THEME"
    ;;
  *)
    echo "unknown command"
    exit 1
    ;;
esac
