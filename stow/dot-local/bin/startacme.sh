#!/usr/bin/env sh

# ~/local/bin/startacme.sh : Acme launcher
# If plumbing web URLs does not work, set environment var BROWSER=none

# Usage:
#     startacme.sh
#     startacme.sh [file]
#     startacme.sh -N [number between 0 and 9 inclusive]

set -e

# Make sure PLAN9 env var and PATH are set properly
if [ -z "$PLAN9" ]; then
	if [ -d "$HOME/local/plan9port" ]; then
		export PLAN9=$HOME/local/plan9port
		export PATH=$PATH:$PLAN9/bin
	elif [ -d "/usr/local/plan9port" ]; then
		export PLAN9=/usr/local/plan9port
		export PATH=$PATH:$PLAN9/bin
	else
		echo "PLAN9 undefined and plan9port install not found at /usr/local/plan9port or $HOME/local/plan9port" >&2
		exit 1
	fi
fi
if ! $(echo "$PATH" | grep "$HOME/bin/acme" >/dev/null 2>&1); then
	export PATH=$HOME/bin/acme:$PATH
fi

# '-N' requires a patched Acme where 'acme -t someTitle' sets the window title
titleparams=""
if [ "$1" = "-N" ]; then
	j=0
	while [ $j -lt 10 ]; do
		if ! $(NAMESPACE="/tmp/ns.$USER.$j" 9p ls acme >/dev/null 2>&1); then
			break
		fi
		j=$(( j + 1 ))
	done
	if [ $j -ge 10 ]; then
		echo "All supported namespace numbers 0 through 9 have a running Acme." >&2
		exit 1
	fi
	export NAMESPACE="/tmp/ns.$USER.$j"
	[ -d "$NAMESPACE" ] || mkdir -p "$NAMESPACE"
	titleparams="-t acme-$j"
	# Uncomment below line if to maintain a cleaner /tmp/ directory
	# (the /tmp/ directory gets cleaned on reboots in any case)
	# trap 'rm -rf "$NAMESPACE"' EXIT
	shift;
fi

# Set start file and pass through other params
startparams="$@"
startfile=$HOME/local/notes/index.txt
if [ "$startparams" = "" ]; then
	if [ -f "$startfile" ]; then
		startparams="-c 2 $startfile"
	fi
fi

# Machine-specific settings
case "$(uname)" in
	Darwin)
		if [ -z "$BROWSER" ]; then
			BROWSER='Mullvad Browser'
		fi
		font="$PLAN9/font/lucsans/unicode.8.font,/mnt/font/LucidaGrande/28a/font"
		altfont="$PLAN9/font/lucsans/boldtypeunicode.7.font,/mnt/font/ComicCode-Medium/26a/font"
		export acmefonts=$(cat <<EOF
$font
$altfont
$HOME/lib/font/uw-ttyp0/t0-18b-uni.font,/mnt/font/PragmataProMono-Regular/32a/font
$HOME/lib/font/cozette/cozette.font,/mnt/font/BQN386/28a/font
EOF
)
		;;
	Linux)
		if [ -z "$BROWSER" ]; then
			if command -v google-chrome >/dev/null 2>&1; then
				BROWSER=google-chrome
			else
				BROWSER=none
			fi
		fi
		#font="/lib/font/bit/luc/unicode.8.font"
		#font="/mnt/font/NotoSans-Regular/12a/font"
		font="/mnt/font/UbuntuMono-Regular/12a/font"
		altfont="/lib/font/bit/lucsans/euro.8.font"
		export acmefonts=$(cat <<EOF
$font
$altfont
EOF
)
		;;
	*)
		BROWSER=none
		;;
esac

# Launch Acme
visibleclicks=1 SHELL=rc BROWSER=$BROWSER \
	$PLAN9/bin/rc $HOME/local/bin/startacme.rc \
	-f $font \
	-F $altfont \
	$titleparams \
	$startparams \
	&
