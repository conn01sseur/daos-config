#!/usr/bin/env sh


#// set variables

scrDir="$(dirname "$(realpath "$0")")"
source "${scrDir}/globalcontrol.sh"
rofiConf="${confDir}/rofi/selector.rasi"


#// set rofi scaling

[[ "${rofiScale}" =~ ^[0-9]+$ ]] || rofiScale=10
r_scale="configuration {font: \"JetBrainsMono Nerd Font ${rofiScale}\";}"
elem_border=$(( hypr_border * 3 ))


#// scale for monitor

if command -v jq &> /dev/null; then
    mon_x_res=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .width')
    mon_scale=$(hyprctl -j monitors | jq '.[] | select(.focused==true) | .scale' | sed "s/\.//")
else
    # Fallback to non-JSON output when jq is missing.
    mon_x_res=$(hyprctl monitors | awk '/focused: yes/{f=1} f && /res:/{print $2; exit}' | cut -d'x' -f1)
    mon_scale=100
fi

if ! printf '%s' "${mon_x_res}" | grep -qE '^[0-9]+$'; then
    mon_x_res=1920
fi
if ! printf '%s' "${mon_scale}" | grep -qE '^[0-9]+$'; then
    mon_scale=100
fi
mon_x_res=$(( mon_x_res * 100 / mon_scale ))


#// generate config

elm_width=$(( (24 + 6 + 4) * rofiScale ))
max_avail=$(( mon_x_res - (4 * rofiScale) ))
col_count=$(( max_avail / elm_width ))
if [ "${col_count}" -lt 1 ]; then
    col_count=5
fi
r_override="window{width:96%;background-color:transparent;} listview{columns:${col_count};lines:1;dynamic:false;fixed-height:false;fixed-columns:false;cycle:true;scrollbar:false;spacing:1em;} element{border:2px;border-radius:8px;border-color:transparent;orientation:vertical;padding:0em;background-color:transparent;} element selected.normal{background-color:transparent;border-color:@select-bg;} element-icon{size:17em;border-radius:8px;background-color:#00000022;} element-text{enabled:false;}"


#// launch rofi menu

currentWall="$(basename "$(readlink "${hydeThemeDir}/wall.set")")"
wallPathArray=("${hydeThemeDir}")
wallPathArray+=("${wallAddCustomPath[@]}")
get_hashmap "${wallPathArray[@]}"
if ! command -v rofi &> /dev/null; then
    notify-send -a "t1" "rofi не установлен" "Нужен rofi для выбора обоев."
    exit 1
fi
[ -d "${thmbDir}" ] || mkdir -p "${thmbDir}"
if command -v magick &> /dev/null; then
    for i in "${!wallList[@]}"; do
        sqrePath="${thmbDir}/${wallHash[i]}.sqre"
        if [ ! -e "${sqrePath}" ]; then
            magick "${wallList[i]}"[0] -strip -thumbnail 500x500^ -gravity center -extent 500x500 "${sqrePath}" 2>/dev/null || true
        fi
    done
fi
if ! command -v parallel &> /dev/null; then
    # Build rofi list without GNU parallel.
    rofiSel=$(
        for i in "${!wallList[@]}"; do
            printf '%s\x00icon\x1f%s/%s.sqre\n' \
                "$(basename "${wallList[i]}")" \
                "${thmbDir}" \
                "${wallHash[i]}"
        done | rofi -dmenu -theme-str "${r_scale}" -theme-str "${r_override}" -config "${rofiConf}" -select "${currentWall}"
    )
else
    rofiSel=$(parallel --link echo -en "\$(basename "{1}")"'\\x00icon\\x1f'"${thmbDir}"'/'"{2}"'.sqre\\n' ::: "${wallList[@]}" ::: "${wallHash[@]}" | rofi -dmenu -theme-str "${r_scale}" -theme-str "${r_override}" -config "${rofiConf}" -select "${currentWall}")
fi


#// apply wallpaper

if [ ! -z "${rofiSel}" ] ; then
    for i in "${!wallPathArray[@]}" ; do
        setWall="$(find "${wallPathArray[i]}" -type f -name "${rofiSel}")"
        [ -z "${setWall}" ] || break
    done
    "${scrDir}/swwwallpaper.sh" -s "${setWall}"
    notify-send -a "t1" -i "${thmbDir}/$(set_hash "${setWall}").sqre" " ${rofiSel}"
fi
