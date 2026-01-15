#!/bin/sh
set -eu

# Prende i valori dall'ambiente (passati da sway), con fallback
GTK_THEME="${GTK_THEME:-Adwaita}"
GTK_SCHEME="${GTK_SCHEME:-default}"
ICON_THEME="${ICON_THEME:-Adwaita}"
CURSOR_THEME="${CURSOR_THEME:-Adwaita}"
CURSOR_SIZE="${CURSOR_SIZE:-24}"
FONT_GTK="${FONT_GTK:-Sans 11}"

# 1) GSettings (GTK native)
gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME"
gsettings set org.gnome.desktop.interface color-scheme "$GTK_SCHEME"
gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME"
gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME"
gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE"
gsettings set org.gnome.desktop.interface font-name "$FONT_GTK"
gsettings set org.gnome.desktop.wm.preferences button-layout ""

# 2) settings.ini per GTK3/GTK4
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

# prefer-dark -> gtk-application-prefer-dark-theme=1
PREFER_DARK=0
[ "$GTK_SCHEME" = "prefer-dark" ] && PREFER_DARK=1

write_gtk_ini() {
  out="$1"
  cat > "$out" <<EOF
[Settings]
gtk-theme-name=$GTK_THEME
gtk-icon-theme-name=$ICON_THEME
gtk-font-name=$FONT_GTK
gtk-cursor-theme-name=$CURSOR_THEME
gtk-cursor-theme-size=$CURSOR_SIZE
gtk-application-prefer-dark-theme=$PREFER_DARK
EOF
}

write_gtk_ini "$HOME/.config/gtk-3.0/settings.ini"
write_gtk_ini "$HOME/.config/gtk-4.0/settings.ini"

# 2b) GTK4: symlink di gtk.css e assets (come nwg-look)
THEME_DIR_USER="$HOME/.themes/$GTK_THEME"
THEME_DIR_SYS="/usr/share/themes/$GTK_THEME"

if [ -d "$THEME_DIR_USER/gtk-4.0" ]; then
  THEME_GTK4_DIR="$THEME_DIR_USER/gtk-4.0"
elif [ -d "$THEME_DIR_SYS/gtk-4.0" ]; then
  THEME_GTK4_DIR="$THEME_DIR_SYS/gtk-4.0"
else
  THEME_GTK4_DIR=""
fi

# Pulisci symlink vecchi (se puntavano a un tema diverso)
rm -f "$HOME/.config/gtk-4.0/gtk.css"
rm -f "$HOME/.config/gtk-4.0/assets"

if [ -n "$THEME_GTK4_DIR" ]; then
  [ -f "$THEME_GTK4_DIR/gtk.css" ] && ln -sf "$THEME_GTK4_DIR/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"
  [ -d "$THEME_GTK4_DIR/assets" ] && ln -sf "$THEME_GTK4_DIR/assets" "$HOME/.config/gtk-4.0/assets"
fi

# 3) XSETTINGS via xsettingsd (serve per app XWayland)
mkdir -p "$HOME/.config/xsettingsd"
cat > "$HOME/.config/xsettingsd/xsettingsd.conf" <<EOF
Net/ThemeName "$GTK_THEME"
Net/IconThemeName "$ICON_THEME"
Gtk/FontName "$FONT_GTK"
Gtk/CursorThemeName "$CURSOR_THEME"
Gtk/CursorThemeSize $CURSOR_SIZE
EOF

# Riavvio xsettingsd (se lo usi)
pkill -x xsettingsd 2>/dev/null || true
nohup xsettingsd >/dev/null 2>&1 &

exit 0
