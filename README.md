# GnomeTools
A set of Raku modules based on Gnome libraries but are mostly gtk version 4 widgets.

# Provided Tools
The set of tools are Raku library modules to help the user with some common GUI widgets and windows. This can be any mix from the Gnome libraries like Gtk, Gsk, Graphene, Gio or any other Gnome library. This library may also contain replacements of widgets which are deprecated in Gnome Gtk 4. Gtk version 3 will not be used because of the dangers to mix them with version 4. All modules are based on the Raku libraries of Gnome::*:api<2>.

## Gtk Version 4

* **GnomeTools::Gtk::Dialog**.
* **GnomeTools::Gtk::DropDown**.
* **GnomeTools::Gtk::MessageDialog**.
* **GnomeTools::Gtk::Statusbar**.
* **GnomeTools::Gtk::Theming**.

# Installing
```
zef install GnomeTools
```
