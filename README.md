# GnomeTools

![artistic-2.0][license-a2-svg] ![GNU Free Documentation License][license-dc-svg].

A set of Raku modules based on Gnome libraries but are mostly gtk version 4 widgets.

# Provided Tools
The set of tools are Raku library modules to help the user with some common GUI widgets and windows. This can be any mix from the Gnome libraries like Gtk, Gsk, Graphene, Gio or any other Gnome library. This library may also contain replacements of widgets which are deprecated in Gnome Gtk 4, although they will only be removed in version 5. Gtk version 3 will not be used because of the dangers to mix them with version 4. All modules are based on the Raku libraries of `Gnome::\*:api<2>`.

## Modules based on Gtk Version 4

* **GnomeTools::Gtk::Application**. An application framework to make it a little bit more simple creating a full fledged program.
* **GnomeTools::Gtk::Dialog**. The dialog is deprecated since version 4.10 of Gtk. I think it is deprecated because it is quite easy to create one yourself. It is still a necessary tool so it is provided in this library.
* **GnomeTools::Gtk::DropDown**. A dropdown widget with some extra tooling around the widget.
* **GnomeTools::Gtk::GridView**. A GridView is like a ListView. The difference is that when the window is not large enough, it wraps to the second column or row depending on its orientation.
* **GnomeTools::Gtk::ListBox**. List boxes are used to show columns of information. The default case is to show text strings. With extra work you are able to show any kind of widget in each row of the listbox. This class needs some extra work to get everything right.
* **GnomeTools::Gtk::ListView**. A ListView is used for the same reason as a ListBox but can handle much longer lists and can handle complex widgets in a row.
* **GnomeTools::Gtk::MessageDialog**. The message dialog is based on the dialog class.
* **GnomeTools::Gtk::Statusbar**. The statusbar is deprecated since version 4.10 of Gtk. With a bit less facilities then the original, it is just like a label widget which takes the total width of its container.
* **GnomeTools::Gtk::Theming**. A small toolbox to set css class names on widgets and to read a css file or text and set the context for all widgets.

## Modules based on Gio

* **GnomeTools::Gio::Menu**. A class to build menus which often go in a menubar at the top of an apllication window.


# Installing
```
zef install GnomeTools
```

# Todo
* All documents, including examples should be visible at [my github pages][doc-site-lnk].
* Documentation needs to be added.
* More classes should be added.
* CSS classes are not set everywhere yet.

# Issues
Please file [any problems here](https://github.com/MARTIMM/GnomeTools/issues).

# Licenses
The code and pod documentation: [Artistic License 2.0`][licence-a2-lnk].
Documentation at [this site][doc-site-lnk] has the [GNU Free Documentation License][licence-dc-lnk].


[license-a2-svg]: http://martimm.github.io/label/License-label.svg
[licence-a2-lnk]: https://opensource.org/license/artistic-2-0
[license-dc-svg]: http://martimm.github.io/label/License-label-docs.svg
[licence-dc-lnk]: https://www.gnu.org/licenses/fdl-1.3.html
[doc-site-lnk]: https://martimm.github.io/content-docs/projects.html