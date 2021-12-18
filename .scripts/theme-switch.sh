#!/bin/bash
if [[ $(xfconf-query -c xsettings -p /Net/ThemeName) == "oomox-materia-red-light" ]] || [[ -n $1 ]]
then
	xfconf-query -c xsettings -p /Net/ThemeName -s "oomox-materia-red-dark"
	xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus-Dark"
	sed -i -e 's/colors: .*/colors: \*dark/' ~/.config/alacritty/alacritty.yml
	sed -i -e 's/Default Light+/Materia Contrast/' ~/.config/Code/User/settings.json
	sed -i -e 's/arc-lenovo-light/arc-lenovo-dark/' ~/.config/ulauncher/settings.json
else
	xfconf-query -c xsettings -p /Net/ThemeName -s "oomox-materia-red-light"
	xfconf-query -c xsettings -p /Net/IconThemeName -s "Papirus-Light"
	sed -i -e 's/colors: .*/colors: \*light/' ~/.config/alacritty/alacritty.yml
	sed -i -e 's/Materia Contrast/Default Light+/' ~/.config/Code/User/settings.json
	sed -i -e 's/arc-lenovo-dark/arc-lenovo-light/' ~/.config/ulauncher/settings.json
fi
