#!/system/bin/sh
# ColorTune shared library. Sourced by colortune, webui.sh and service.sh.
# All values are percentages, 100 = normal.
#   contrast           50..200  SurfaceFlinger 1015 (color matrix)
#   saturation          0..400  SurfaceFlinger 1022
#   RGB color balance  50..100  per-channel gain, folded into the same 1015 matrix

CT_MODDIR=${CT_MODDIR:-/data/adb/modules/colortune}
CONF_DIR=${CONF_DIR:-/data/adb/colortune}
CONF=$CONF_DIR/config   # saved settings
LIVE=$CONF_DIR/live     # what is on screen right now (includes unsaved previews)

is_int() {
  case "$1" in
    ''|*[!0-9]*) return 1 ;;
  esac
  [ "${#1}" -le 6 ]
}

# clamp VALUE LOW HIGH -> result in $CL (no subshell)
clamp() {
  CL=$1
  while [ "${#CL}" -gt 1 ] && [ "${CL#0}" != "$CL" ]; do CL=${CL#0}; done
  [ "$CL" -lt "$2" ] && CL=$2
  [ "$CL" -gt "$3" ] && CL=$3
}

reset_vars() {
  CONTRAST=100; SATURATION=100
  WB_R=100; WB_G=100; WB_B=100
  AUTO=1; THEME=dark
}

# Plain key=value parser, never executes the file
read_file() {
  [ -f "$1" ] || return 0
  while IFS='=' read -r _k _v; do
    case "$_k" in
      CONTRAST)   is_int "$_v" && CONTRAST=$_v ;;
      SATURATION) is_int "$_v" && SATURATION=$_v ;;
      WB_R)       is_int "$_v" && WB_R=$_v ;;
      WB_G)       is_int "$_v" && WB_G=$_v ;;
      WB_B)       is_int "$_v" && WB_B=$_v ;;
      AUTO)       is_int "$_v" && AUTO=$_v ;;
      THEME)      case "$_v" in dark|light) THEME=$_v ;; esac ;;
    esac
  done < "$1"
}

normalize() {
  clamp "$CONTRAST" 50 200;   CONTRAST=$CL
  clamp "$SATURATION" 0 400;  SATURATION=$CL
  clamp "$WB_R" 50 100;       WB_R=$CL
  clamp "$WB_G" 50 100;       WB_G=$CL
  clamp "$WB_B" 50 100;       WB_B=$CL
  clamp "$AUTO" 0 1;          AUTO=$CL
}

load_saved() { reset_vars; read_file "$CONF"; normalize; }
load_live()  { reset_vars; read_file "$CONF"; read_file "$LIVE"; normalize; }

save_conf() {
  mkdir -p "$CONF_DIR"
  printf "CONTRAST=%s\nSATURATION=%s\nWB_R=%s\nWB_G=%s\nWB_B=%s\nAUTO=%s\nTHEME=%s\n" \
    "$CONTRAST" "$SATURATION" "$WB_R" "$WB_G" "$WB_B" "$AUTO" "$THEME" > "$CONF"
}

save_live() {
  mkdir -p "$CONF_DIR"
  printf "CONTRAST=%s\nSATURATION=%s\nWB_R=%s\nWB_G=%s\nWB_B=%s\n" \
    "$CONTRAST" "$SATURATION" "$WB_R" "$WB_G" "$WB_B" > "$LIVE"
}

# 130 -> 1.30
fmt_pct() {
  printf "%d.%02d" $(($1 / 100)) $(($1 % 100))
}

# 10800 -> 1.0800
fmt4() {
  printf "%d.%04d" $(($1 / 10000)) $(($1 % 10000))
}

# translation = 0.5 * (1 - C), C in percent -> (100 - C) / 200
fmt_trans() {
  _n=$(( (100 - $1) * 5 ))   # thousandths
  _s=""
  if [ "$_n" -lt 0 ]; then
    _s="-"
    _n=$(( -_n ))
  fi
  printf "%s%d.%03d" "$_s" $((_n / 1000)) $((_n % 1000))
}

apply_sat() {
  service call SurfaceFlinger 1022 f "$(fmt_pct "$SATURATION")" >/dev/null 2>&1
}

# Contrast and RGB color balance share one color matrix:
#   out = C * (gain * in - 0.5) + 0.5  =  (C * gain) * in + 0.5 * (1 - C)
apply_matrix() {
  if [ "$CONTRAST" -eq 100 ] && [ "$WB_R" -eq 100 ] && [ "$WB_G" -eq 100 ] && [ "$WB_B" -eq 100 ]; then
    service call SurfaceFlinger 1015 i32 0 >/dev/null 2>&1
  else
    _t=$(fmt_trans "$CONTRAST")
    service call SurfaceFlinger 1015 i32 1 \
      f "$(fmt4 $((CONTRAST * WB_R)))" f 0 f 0 f 0 \
      f 0 f "$(fmt4 $((CONTRAST * WB_G)))" f 0 f 0 \
      f 0 f 0 f "$(fmt4 $((CONTRAST * WB_B)))" f 0 \
      f "$_t" f "$_t" f "$_t" f 1 >/dev/null 2>&1
  fi
}

apply_all() {
  apply_sat
  apply_matrix
}
