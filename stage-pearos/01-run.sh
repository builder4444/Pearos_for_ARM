#!/bin/bash
set -euo pipefail

# Configure LightDM autologin and default XFCE session.
install -d /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/20-autologin.conf <<'CFG'
[Seat:*]
autologin-user=pi
autologin-session=xfce
user-session=xfce
greeter-session=lightdm-gtk-greeter
CFG

# System-wide defaults for new users.
install -d /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml
install -d /etc/skel/.config/autostart

cat > /etc/skel/.xsession <<'XSESS'
startxfce4
XSESS

cat > /etc/skel/.config/autostart/plank.desktop <<'DESKTOP'
[Desktop Entry]
Type=Application
Name=Plank
Exec=plank
X-GNOME-Autostart-enabled=true
DESKTOP

cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="WhiteSur-dark"/>
    <property name="IconThemeName" type="string" value="WhiteSur"/>
    <property name="CursorThemeName" type="string" value="Bibata-Modern-Ice"/>
  </property>
</channel>
XML

cat > /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="workspace0" type="empty">
          <property name="last-image" type="string" value="/usr/share/backgrounds/pearos-like/nordic-forest.jpg"/>
        </property>
      </property>
    </property>
  </property>
</channel>
XML

# Ensure the default pi user gets the same look.
if id pi >/dev/null 2>&1; then
  cp -a /etc/skel/. /home/pi/
  chown -R pi:pi /home/pi
fi
