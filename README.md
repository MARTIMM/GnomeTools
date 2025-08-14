# GnomeTools
A set of Raku modules based on Gnome libraries but are mostly gtk version 4 widgets.

# Provided Tools
The set of tools are Raku library modules to help the user with some common GUI widgets and windows. This can be any mix from the Gnome libraries like Gtk, Gsk, Graphene, Gio or any other Gnome library. This library may also contain replacements of widgets which are deprecated in Gnome Gtk 4. Gtk version 3 will not be used because of the dangers to mix them with version 4. All modules are based on the Raku libraries of Gnome::*:api<2>.

## Gtk Version 4

* **GnomeTools::Gtk::Dialog**. The dialog is deprecated since version 4.10 of Gtk. I think it is deprecated because it is quite easy to create one yourself. It is still a necessary tool so it is provided in this library.
* **GnomeTools::Gtk::MessageDialog**. The message dialog is based on the dialog class.
* **GnomeTools::Gtk::DropDown**. A dropdown widget with some extra tooling around the widget.
* **GnomeTools::Gtk::Statusbar**. The statusbar is deprecated since version 4.10 of Gtk. With a bit less facilities then the original, it is just like a label widget which takes the total width of its container.
* **GnomeTools::Gtk::Theming**. A small toolbox to set css class names on widgets and to read a css file or text and set the context for all widgets.

# Installing
```
zef install GnomeTools
```
