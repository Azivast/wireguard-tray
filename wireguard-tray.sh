#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

cd "$(dirname "$(readlink -f "${0:-.}")")"

AWK_SEPERATORS='[: ]+'
AWK_DEV_PARSE='/(<([^>]+,)?(UP|DOWN)(,[^>]+)?>|\s(UP|DOWN)\s)/ {print $2;system("")}'
ICON_UP='wireguard_logo_on.svg'
ICON_DOWN='wireguard_logo_off.svg'

function create_menu_string() {
	for dev in $(ip link show type wireguard | \
		awk -F "${AWK_SEPERATORS}" "${AWK_DEV_PARSE}")
	do
		if [[ -n "$(ip link show "${dev}" up type wireguard)" ]]
		then
			echo -n "${dev} up|"
		else
			echo -n "${dev} down|"
		fi
	done
	echo -n '|Quit!quit'
}

function is_up() {
	[[ -z "$(ip link show up type wireguard)" ]] && return 1
	return 0
}

ip monitor link | \
	awk -F "${AWK_SEPERATORS}" "${AWK_DEV_PARSE}" | \
	while read dev
	do
		echo "menu:$(create_menu_string)"
		if is_up
		then
			echo "icon:${ICON_UP}"
			echo 'tooltip:Wireguard up'
		else
			echo "icon:${ICON_DOWN}"
			echo 'tooltip:Wireguard down'
		fi
	done | \
	yad --notification \
		--listen \
		--title=Wireguard \
		--command= \
		--no-middle \
		--menu="$(create_menu_string)" \
		--image="$(is_up && echo "${ICON_UP}" || echo "${ICON_DOWN}")" \
		--tooltip="$(is_up && echo 'Wireguard up' || echo 'Wireguard down')"
