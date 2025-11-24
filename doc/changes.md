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

