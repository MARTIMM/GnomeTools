* 2026 06 21 0.8.2
  * Make variable $!application-window readable. 
  * make a 2nd method `.set-window-content()` in **GnomeTools::Gtk::Application.
    ```
    multi method set-window-content (
      $widget-helper-object, Str $widget-helper-method,
      $menu-helper-object, Str $menu-helper-method,
      *%options
    )
    ```
    This method makes shure that the application-window exists before content and menu is asked for.
  * Let **GnomeTools::Gtk::Application** handle `.add-action()` and `.set-accels-for-action()` methods.

* 2026 06 09 0.8.1
  * Can do asynchronous dropping now. Objects can be dragged from a `firefox` browser, all gnome applications like `files` (originally called `nautilus`) but not from any QT based applications like `konqueror` or `dolphin`. There are different opinions how to send the data. This is seen on a linux Fedora system version 43 and a KDE desktop with x11 support. Wayland (not only x11) is said to improve on the problems about this issue. There will be no effort in improving on x11.

* 2026 06 08 0.8.0
  * Add module **GnomeTools::Gtk::DND** to setup drag and drop. There are still a few items to add but tests are promising.

* 2026 06 02 0.7.0
  * Add module **GnomeTools::Gtk::Shortcut** to define shortcut keys and run callback method when pressed.

* 2026 04 06 0.6.6
  * Bug fixed. Application accepted the specific `GApplicationFlags` type while it can be or-ed with several of those. So it is changed into `UInt`.

* 2026 03 01 0.6.5
  * Fixed a subtle problem in menu items. It wasn't possible to refer to the same methods in different objects.

* 2026 02 27 0.6.4
  * Bug fix in selection method `.set-selection()`.
  * Auto selection is turned off. Problems arise when `.set-selection-changed()` is used. The specified callback will not be called when first item is selected.

* 2026 02 25 0.6.3
  * Add method .set-selection() to **GnomeTools::Gtk::R-ListModel**.

* 2026 02 13 0.6.2
  * Added `.get-n-items()` to **GnomeTools::Gtk::R-ListModel**. Added to pod doc as well.
  * Bug fix in `.teardown()`.

* 2026 02 08 0.6.1
  * Application must handle quit method

* 2026 01 29 0.6.0
  * Add class **GnomeTools::Gtk::GridView**.

* 2026 01 13 0.5.2
  * Introduced role **GnomeTools::Gtk::R-ListModel** to move many methods from ListView. This makes it easier to make future classes like GridView and ColumnView. Also the eventconnection must not take place in BUILD() but later, called via an extra method `.set-events()`.
  * **GnomeTools::Gtk::DropDown** changed to use the routines from R-ListModel and to use the `.set-events()` method.

* 2026 01 05 0.5.1
  * Pod doc completed for **GnomeTools::Gtk::ListView**.

* 2025 12 15 0.5.0
  * Add **GnomeTools::Gtk::ListView**.
  * Multi/single selection added.

* 2025 12 15 0.4.3
  * Thinking about tools for Glib and GObject

* 2025 12 02 0.4.2
  * Change class **GnomeTools::Gtk::Menu** to **GnomeTools::Gio::Menu** because all menu classes come from distribuion `Gnome::Gio`.

* 2025 11 24 0.4.0
  * Add a class **Application**.

* 2025 11 17 0.3.2
  * Add method `.get-list() to **ListBox**.

* 2025 10 19 0.3.1
  * Add css class `listbox-tool` for a **ListBox**. Example use;
  ```
  /* hover over activatable rows */
  .listbox-tool row.activatable:hover {
    background-color: transparent;
    color: pink;
  }

  /* selected rows */
  .listbox-tool row.activatable:selected {
    background-color: transparent;
    color: #008f00;
  }

  /* hover over selected rows
  .listbox-tool row.activatable:selected:hover {
    background-color: #20df20;
    color: #008f00;
  }
  ```

* 2025 10 08 0.3.0
  * Add class **Menu**.
  * Menu created in **Application** and dropped module for **MenuBar**.

* 2025 09 14 0.2.3
  * Add reset-list to **ListBox.**
  * Add a sorting function. Doesn't seem to work either >sic<

* 2025 09 09 0.2.2
  * Make 'row-selected' event available

* 2025-09-05 0.2.1
  * Bugfix of 'destroy' event in **Dialog**. Should've trap 'close-request'.

* 2025-08-21 0.2.0
  * Add class **ListBox** for easy handling of a listbox

* 2025-08-14 0.1.1
  * React when dropdown selection changes.

* 2025-08-05 0.1.0
  * **Statusbar** is rewritten and is a simplified version of that of Gnome. It is added to this toolbox because it is also deprecated since version 4.10.

* 2025-08-04 0.0.3
  * Test theming module with `xt/dialog.rakutest`.

* 2025-07-30 0.0.2
  * Bugfixes
  * Add **DropDown** class.

* 2025-07-29 0.0.1
  * Setup of project
  * Add classes **Dialog**, **MessageDialog**, **Statusbar**, **Theming**.

