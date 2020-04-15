#!/bin/bash
original1=$(head -n 1 colors.list | cut -d ',' -f2)
original2=$(head -n 1 colors.list | cut -d ',' -f3)
original3=$(head -n 1 colors.list | cut -d ',' -f4)

loop=1
loops=$(wc -l colors.list | sed 's/colors.list//g')

function newColor() {
	sed -i "s/$original1/$color1/g" $1
	sed -i "s/$original2/$color2/g" $1
	sed -i "s/$original3/$color3/g" $1
}

function oldColor() {
	sed -i "s/$color1/$original1/g" $1
	sed -i "s/$color2/$original2/g" $1
	sed -i "s/$color3/$original3/g" $1
}
function renderIcon() {
	for svg in icons/src/fullcolor/*/*.svg; do
		type=$(echo "$svg" | cut -d '/' -f4)
		icon=$(echo "$svg" | cut -d '/' -f5)
		for size in 8 16 24 32 48 256; do
			for scale in @1x @2x; do
				factor=${scale#"@"}
				factor=${factor%"x"}
				scale=${scale#"@1x"}
				path=icons/"$1"/"$size"x"$size""$scale"/"$type"/
				mkdir -p "$path"
				dpi=$(( $size * $factor ))
				height=$(inkscape -H $svg | cut -d . -f1)
				width=$(inkscape -W $svg | cut -d . -f1)
				if [[ $height -gt $width ]]; then
					inkscape -z "$svg" -D -e "$path/${icon%svg}png" -h "$dpi" > /dev/null 2>&1
				else
					inkscape -z "$svg" -D -e "$path/${icon%svg}png" -w "$dpi" > /dev/null 2>&1
				fi
				height=$(identify -format "%h" "$path/${icon%svg}png")
				width=$(identify -format "%w" "$path/${icon%svg}png")
				if [[ $height -gt $width ]]; then
					convert "$path/${icon%svg}png" -background none -gravity center -extent "$height" "$path/${icon%svg}png" > /dev/null 2>&1
				elif [[ $height -lt $width ]]; then
					convert "$path/${icon%svg}png" -background none -gravity center -extent x"$width" "$path/${icon%svg}png" > /dev/null 2>&1
				fi
			done
		done
	done
	cp -r icons/src/scalable/ "icons/$1/scalable"
	cp -r icons/src/scalable-max-32/ "icons/$1/scalable-max-32"
	echo "[Icon Theme]" > "icons/$1/index.theme"
	echo "Name=$1" >> "icons/$1/index.theme"
	cat icons/src/index.theme >> "icons/$1/index.theme"
	echo "Inherits=Humanity,hicolor" >> "icons/$1/index.theme"
	echo "Example=folder" >> "icons/$1/index.theme"
}
function shapetastic() {
	for svg in icons/src/fullcolor/*/*.svg; do
		one=$(echo "StandardCircleSquircle" | sed "s/$1//g" | sed -e 's/\([A-Z][a-z]*\)/ &/g' | cut -d ' ' -f2)
		two=$(echo "StandardCircleSquircle" | sed "s/$1//g" | sed -e 's/\([A-Z][a-z]*\)/ &/g' | cut -d ' ' -f3)
		hide=$(echo "$one\\|$two")
		cat "$svg" | grep -n inkscape:label | grep "$hide" | cut -d \: -f1 | while read line; do
			for i in -1 1 2 3; do
				display=$(("$line" + "$i"))
				display="$display"s
				sed -i "$display/display:inline/display:none/" "$svg"
			done
		done
		cat "$svg" | grep -n inkscape:label | grep "$1" | cut -d \: -f1 | while read line; do
			for i in -1 1 2 3; do
				display=$(("$line" + "$i"))
				display="$display"s
				sed -i "$display/display:none/display:inline/" "$svg"
			done
		done
	done
}

function symlink() {
	for list in icons/src/lists/*/*; do
		while read ALIAS ; do
			variant=$(echo "$list" | cut -d '/' -f4)
			type=$(echo "$list" | cut -d '/' -f5| cut -d '.' -f1)
			FROM=${ALIAS% *}
			TO=${ALIAS#* }
			if [[ "$variant" == fullcolor ]]; then
				for size in 8 16 24 32 48 256; do
					for scale in @1x @2x; do
						scale=${scale#"@1x"}
						path=icons/"$1"/"$size"x"$size""$scale"/"$type"
						if [[ -e "$path/$FROM" ]]; then
							ln -s "$FROM" "$path/$TO"
						fi
					done
				done
			elif [[ "$path" == scalable ]]; then
				if [[ -e "icons/$1/scalable/$FROM" ]]; then
					ln -s "$FROM" "icons/$1/scalable/$TO"
				fi
			fi
		done < "$list"
	done
}

function exportwallpaper() {
	inkscape -z backgrounds/StarWallpaper0.svg -D -e backgrounds/StarWallpaper0"$name".png > /dev/null 2>&1
	printf "<wallpaper deleted="\"false\"">\n<name>Star Labs Systems - NAME</name>\n<filename>/usr/share/backgrounds/StarLabs/WALLPAPER</filename>\n<options>zoom</options>\n<shade_type>solid</shade_type>\n<pcolor>#000000</pcolor>\n<scolor>#000000</scolor>\n<artist>StarLabs</artist>\n</wallpaper>\n" | sed "s/WALLPAPER/StarWallpaper0$name.png/g" | sed "s/NAME/$name/g" >> backgrounds/StarLabs.xml
	sed -i "/backgrounds_sources = \[/a 'StarWallpaper0$name.png'," backgrounds/meson.build
}

function creategtk3() {
	cp -r "gtk/Light" "gtk/$theme-Light"
	cp -r "gtk/Default" "gtk/$theme"
	cp -r "gtk/Dark" "gtk/$theme-Dark"

        sed -i "s/@VariantThemeName@/$theme-Light/g" "gtk/$theme"-Light/index.theme "gtk/$theme"-Light/gtk-3.0/meson.build "gtk/$theme"-Light/gtk-2.0/meson.build
	sed -i "s/@VariantThemeName@/$theme/g" "gtk/$theme"/index.theme "gtk/$theme"/gtk-3.0/meson.build "gtk/$theme"/gtk-2.0/meson.build
	sed -i "s/@VariantThemeName@/$theme-Dark/g" "gtk/$theme"-Dark/index.theme "gtk/$theme"-Dark/gtk-3.0/meson.build "gtk/$theme"-Dark/gtk-2.0/meson.build

	sed -i "s/@LightThemeName@/$theme/g" "gtk/$theme"-Dark/gtk-3.0/meson.build "gtk/$theme"-Light/gtk-3.0/meson.build

#	sed -i "s/@ThemeName@/StarLabs/g" "gtk/$theme"/index.theme "gtk/$theme"-Dark/index.theme

	echo "subdir('$theme-Light')" >> "gtk/meson.build"
	echo "subdir('$theme')" >> "gtk/meson.build"
	echo "subdir('$theme-Dark')" >> "gtk/meson.build"
}

function creategtk2() {
	newColor gtk/"$theme"/gtk-2.0/assets.svg
	newColor gtk/"$theme"/gtk-2.0/assets-external.svg
	newColor gtk/"$theme"-Dark/gtk-2.0/assets.svg
	newColor gtk/"$theme"-Dark/gtk-2.0/assets-external.svg
	newColor gtk/"$theme"-Light/gtk-2.0/assets.svg
	newColor gtk/"$theme"-Light/gtk-2.0/assets-external.svg
	newColor gtk/"$theme"/gtk-2.0/gtkrc
	newColor gtk/"$theme"-Dark/gtk-2.0/gtkrc
	newColor gtk/"$theme"-Light/gtk-2.0/gtkrc
	for i in `cat gtk/"$theme"-Light/gtk-2.0/assets.txt`; do
		if [[ -f gtk/"$theme"-Light/gtk-2.0/assets/"$i".png ]]; then
			rm gtk/"$theme"-Light/gtk-2.0/assets/"$i".png
		fi
		inkscape --export-id="$i" \
			--export-id-only \
			--export-background-opacity=0 \
			--export-png=gtk/"$theme"-Light/gtk-2.0/assets/"$i".png gtk/"$theme"-Light/gtk-2.0/assets.svg
		optipng -o7 --quiet gtk/"$theme"-Light/gtk-2.0/assets/"$i".png
	done
	for i in `cat gtk/"$theme"/gtk-2.0/assets.txt`; do
		if [[ -f gtk/"$theme"/gtk-2.0/assets/"$i".png ]]; then
			rm gtk/"$theme"/gtk-2.0/assets/"$i".png
		fi
		inkscape --export-id="$i" \
			--export-id-only \
			--export-background-opacity=0 \
			--export-png=gtk/"$theme"/gtk-2.0/assets/"$i".png gtk/"$theme"/gtk-2.0/assets.svg
		optipng -o7 --quiet gtk/"$theme"/gtk-2.0/assets/"$i".png
	done
	for i in `cat gtk/"$theme"-Dark/gtk-2.0/assets.txt`; do
		if [[ -f gtk/"$theme"-Dark/gtk-2.0/assets/"$i".png ]]; then
			rm gtk/"$theme"-Dark/gtk-2.0/assets/"$i".png
		fi
		inkscape --export-id="$i" \
			--export-id-only \
			--export-background-opacity=0 \
			--export-png=gtk/"$theme"-Dark/gtk-2.0/assets/"$i".png gtk/"$theme"-Dark/gtk-2.0/assets.svg
		optipng -o7 --quiet gtk/"$theme"-Dark/gtk-2.0/assets/"$i".png
	done

	for i in `cat gtk/"$theme"-Light/gtk-2.0/assets-external.txt`; do
		if [[ -f gtk/"$theme"-Light/gtk-2.0/assets/"$i".png ]]; then
			rm gtk/"$theme"-Light/gtk-2.0/assets/"$i".png
		fi
		inkscape --export-id="$i" \
			--export-id-only \
			--export-background-opacity=0 \
			--export-png=gtk/"$theme"-Light/gtk-2.0/assets/"$i".png gtk/"$theme"-Light/gtk-2.0/assets-external.svg
		optipng -o7 --quiet gtk/"$theme"-Light/gtk-2.0/assets/"$i".png
	done
	for i in `cat gtk/"$theme"/gtk-2.0/assets-external.txt`; do
		if [[ -f gtk/"$theme"/gtk-2.0/assets/"$i".png ]]; then
			rm gtk/"$theme"/gtk-2.0/assets/"$i".png
		fi
		inkscape --export-id="$i" \
			--export-id-only \
			--export-background-opacity=0 \
			--export-png=gtk/"$theme"/gtk-2.0/assets/"$i".png gtk/"$theme"/gtk-2.0/assets-external.svg
		optipng -o7 --quiet gtk/"$theme"/gtk-2.0/assets/"$i".png
	done
	for i in `cat gtk/"$theme"-Dark/gtk-2.0/assets-external.txt`; do
		if [[ -f gtk/"$theme"-Dark/gtk-2.0/assets/"$i".png ]]; then
			rm gtk/"$theme"-Dark/gtk-2.0/assets/"$i".png
		fi
		inkscape --export-id="$i" \
			--export-id-only \
			--export-background-opacity=0 \
			--export-png=gtk/"$theme"-Dark/gtk-2.0/assets/"$i".png gtk/"$theme"-Dark/gtk-2.0/assets-external.svg
		optipng -o7 --quiet gtk/"$theme"-Dark/gtk-2.0/assets/"$i".png
	done
}

function creategnome() {
	cp -r "gnome-shell/Dark" "gnome-shell/$theme"
	cp -r "gnome-shell/Light" "gnome-shell/$theme-Light"

	if [[ "$theme" == 'StarLabs' ]]; then
		sed -i "s/install_dir = /install_dir = join_paths(gnomeshell_theme_dir, '@VariantThemeName@')/g" "gnome-shell/$theme/meson.build"
		sed -i "s/install_dir = /install_dir = join_paths(theme_dir, '@VariantThemeName@', 'gnome-shell')/g" "gnome-shell/$theme-Light/meson.build"
	else
		sed -i "s/install_dir = /install_dir = join_paths(theme_dir, '@VariantThemeName@', 'gnome-shell')/g" "gnome-shell/$theme/meson.build" "gnome-shell/$theme-Light/meson.build"
	fi

	sed -i "s/@VariantThemeName@/$theme/g" "gnome-shell/$theme/meson.build"
	sed -i "s/@VariantThemeName@/$theme-Light/g" "gnome-shell/$theme-Light/meson.build"
	sed -i "s/@LightThemeName@/$theme/g" "gnome-shell/$theme-Light/meson.build"

	echo "subdir('$theme')" >> "gnome-shell/meson.build"
	echo "subdir('$theme-Light')" >> "gnome-shell/meson.build"
}

# function createSession() {
#	themelower=$(echo $theme | tr '[:upper:]' '[:lower:]')
#	cp background/THEMENAME.desktop "background/$theme.desktop"
#	sed -i "/install_dir: gnomeshell_mode_dir,/p $theme.desktop" background/meson.build
# }

function pointandshoot() {
	printf "install_subdir('$theme',\ninstall_dir: icon_dir,\nstrip_directory: false,\nexclude_files: ['meson.build'],\n)\n\n" >> icons/meson.build
	newColor icons/cursors/cursors.svg
	mkdir -p icons/$theme/cursors
	echo "[Icon Theme]" > icons/$theme/cursor.theme
	echo "Name=$theme" >> icons/$theme/cursor.theme
	for dpi in x1 x1_5 x2; do
		mkdir -p "icons/$theme/$dpi"
	done
	for cursor in icons/cursors/config/*.cursor; do
		NAME=$cursor
		NAME=${NAME##*/}
		NAME=${NAME%.*}
#		echo -ne "\033[0KGenerating cursor png $NAME\\r"
		if [[ $NAME == 'wait' ]] || [[ $NAME == 'progress' ]]; then
			for i in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24; do
				inkscape -i "$NAME-$i" -d 90 -f icons/cursors/cursors.svg -e "icons/$theme/x1/$NAME-$i.png" > /dev/null
				inkscape -i "$NAME-$i" -d 135 -f icons/cursors/cursors.svg -e "icons/$theme/x1_5/$NAME-$i.png" > /dev/null
				inkscape -i "$NAME-$i" -d 180 -f icons/cursors/cursors.svg -e "icons/$theme/x2/$NAME-$i.png" > /dev/null
			done
			xcursorgen -p "icons/$theme" "$cursor" "icons/$theme/cursors/$NAME"
		else
			inkscape -i $NAME -d 90 -f icons/cursors/cursors.svg -e "icons/$theme/x1/$NAME.png" > /dev/null
			inkscape -i $NAME -d 135 -f icons/cursors/cursors.svg -e "icons/$theme/x1_5/$NAME.png" > /dev/null
			inkscape -i $NAME -d 180 -f icons/cursors/cursors.svg -e "icons/$theme/x2/$NAME.png" > /dev/null
			xcursorgen -p "icons/$theme" "$cursor" "icons/$theme/cursors/$NAME"
		fi
	done
	for dpi in x1 x1_5 x2; do
		rm -r "icons/$theme/$dpi"
	done
	while read ALIAS ; do
		TO=${ALIAS% *}
		FROM=${ALIAS#* }
		if [[ -e "icons/$theme/cursors/$FROM" ]] && ! [[ -e "icons/$theme/cursors/$TO" ]]; then
			ln -s "$FROM" "icons/$theme/cursors/$TO"
		fi
	done < icons/cursors/cursorList
}

clear
echo '  _____ _             _           _'
echo ' /  ___| |           | |         | |'
echo ' \ `--.| |_ __ _ _ __| |     __ _| |__  ___'
echo '  `--. \ __/ _` | '"'"'__| |    / _` | '"'"'_ \/ __|'
echo ' /\__/ / || (_| | |  | |___| (_| | |_) \__ \'
echo ' \____/ \__\__,_|_|  \_____/\__,_|_.__/|___/'
echo
echo '*************** Icon Renderer **************'
echo
echo "Which components would you like to assemble?"
select component in "All" "Backgrounds" "GTK-2.0" "GTK-3.0" "Gnome" "Cursors" "Icons" "Debian"
do
	if [[ $component == "All" ]]; then
		component="Backgrounds GTK Gnome Cursors Icons Debian"
	fi
	echo $component
	break
done

# rm -r output
while read palette ; do
	lowername=$(echo "$palette" | cut -d ',' -f1 | tr '[:upper:]' '[:lower:]')
	name=$(echo "${palette^}" | cut -d ',' -f1)
	color1=$(echo "$palette" | cut -d ',' -f2)
	color2=$(echo "$palette" | cut -d ',' -f3)
	color3=$(echo "$palette" | cut -d ',' -f4)
	theme=$(echo "StarLabs"-"$name" | sed 's/-Blue//g')

	echo -ne "\033[0KGenerating $theme $loop / $loops\\r"
	# Start Backgrounds
	if [[ "$component" == *"Backgrounds"* ]]; then
		if [[ "$loop" == 1 ]]; then
			printf "backgrounds_dir = join_paths(get_option('datadir'), 'backgrounds')\ninstall_dir =join_paths(backgrounds_dir, meson.project_name())\nbackgrounds_sources = [\n]\ninstall_data(backgrounds_sources,\ninstall_dir: install_dir)\nxml_dir = join_paths(get_option('datadir'), 'gnome-background-properties')\nxml_sources = [\n'StarLabs.xml',\n]\ninstall_data(xml_sources, install_dir: xml_dir)" > "backgrounds/meson.build"
			cat "backgrounds/master.xml" > "backgrounds/StarLabs.xml"
		fi
		newColor backgrounds/StarWallpaper0.svg
		exportwallpaper
		if [[ "$loop" -eq "$loops" ]]; then
			for i in 1 2 3 4 5 6 7 8 9 10 11 12; do
				sed -i "/backgrounds_sources = \[/a 'StarWallpaper$i.jpg'," backgrounds/meson.build
			done
			sed -i "/backgrounds_sources = \[/a 'StarWallpaper0.png'," backgrounds/meson.build
			echo "</wallpapers>" >> "backgrounds/StarLabs.xml"
		fi
		oldColor backgrounds/StarWallpaper0.svg
	fi
	# End Backgrounds

	# Start GTK3
	if [[ "$component" == *"GTK-3.0"* ]]; then
		if [[ "$loop" == 1 ]]; then
			rm -r gtk/StarLab*
			rm gtk/meson.build
		fi
		creategtk3
		newColor "gtk/$theme/gtk-3.0/gtk-light.scss"
		newColor "gtk/$theme/gtk-3.0/gtk.scss"
		newColor "gtk/$theme/gtk-3.0/gtk-dark.scss"
	fi
	# End GTK3
	# Start GTK2
	if [[ "$component" == *"GTK-2.0"* ]]; then
		creategtk2
	fi
	# End GTK2

	# Start Gnome
	if [[ "$component" == *"Gnome"* ]]; then
		if [[ "$loop" == 1 ]]; then
			rm -r gnome-shell/StarLab*
#			rm gnome-shell/meson.build
			echo "sassc = find_program('sassc')" > gnome-shell/meson.build
			echo "gnome = import('gnome')" >> gnome-shell/meson.build
			echo "gresources_xml_parser = find_program('gresources-xml-parser.py')" >> gnome-shell/meson.build
		fi
		creategnome
		newColor "gnome-shell/$theme/gnome-shell.scss"
	fi
	# End Gnome

	# Start Cursors
	if [[ "$component" == *"Cursors"* ]]; then
		if [[ "$loop" == 1 ]]; then
			rm -r icons/StarLab*
			printf "icon_dir = join_paths(get_option('prefix'), 'share/icons')\n" > icons/meson.build
		fi
		newColor icons/cursors/cursors.svg
		pointandshoot
		oldColor icons/cursors/cursors.svg
	fi
	# End Cursors

	# Start Icons
	if [[ "$component" == *"Icons"* ]]; then
		newColor "icons/src/fullcolor/*/*.svg"
	for shape in Standard Circle Squircle; do
		dir=$( echo "$theme"-"$shape" | sed 's/-Standard//g')
			shapetastic "$shape"
			renderIcon "$dir"
			if [[ "$shape" == Circle ]]; then
				printf "install_subdir('$dir',\ninstall_dir: icon_dir,\nstrip_directory: false,\nexclude_files: ['meson.build'],\n)\n\n" >> icons/meson.build
				cp icons/src/circle.svg "icons/$dir/scalable/actions/view-app-grid-symbolic.svg"
			elif [[ "$shape" == Squircle ]]; then
				printf "install_subdir('$dir',\ninstall_dir: icon_dir,\nstrip_directory: false,\nexclude_files: ['meson.build'],\n)\n\n" >> icons/meson.build
				cp icons/src/squircle.svg "icons/$dir/scalable/actions/view-app-grid-symbolic.svg"
			fi
			symlink "$dir"
		done
		oldColor "icons/src/fullcolor/*/*.svg"
	fi
	# End Icons
	# Start Debian Package
	if [[ "$component" == *"Debian"* ]]; then
		if [[ "$loop" == 1 ]]; then
			cp debian/control.in debian/control
		fi
		if [[ "$name" != 'Blue' ]]; then
			printf "Package: starlabstheme-$lowername\nArchitecture: all\nDepends: \${shlibs:Depends},\n\${misc:Depends},\nDescription: Star Labs Theme.\n\n" >> debian/control
			printf "usr/share/themes/StarLabs-$name/\nusr/share/themes/StarLabs-$name-Dark/\nusr/share/themes/StarLabs-$name-Light/\nusr/share/icons/StarLabs-$name/\nusr/share/icons/StarLabs-$name-Circle/\nusr/share/icons/StarLabs-$name-Squircle/\n" > "debian/starlabstheme-$lowername.install"
		fi
	fi
	# End Debian Package


	loop=$(( $loop + 1 ))
done < colors.list
