use v6.d;

# Dialog seems to be deprecated since 4.10 so here we have our own

use GnomeTools::Gtk::Statusbar;
use GnomeTools::Gtk::Theming;

use Gnome::Gtk4::T-enums:api<2>;
use Gnome::Gtk4::Window:api<2>;
use Gnome::Gtk4::Grid:api<2>;
use Gnome::Gtk4::Button:api<2>;
use Gnome::Gtk4::Box:api<2>;
use Gnome::Gtk4::Label:api<2>;

use Gnome::Glib::N-MainLoop:api<2>;

use Gnome::N::N-Object:api<2>;

#-------------------------------------------------------------------------------
=begin pod
=TITLE GnomeTools::Gtk::Dialog
=head1 Description

This module is used to setup a dialog window. It is made as a convenience and because it will be deprecated in Gtk version 5.

The contents of the dialog is a grid. The first column is used for a label to describe what is in the next columns. At the bottom is a row where buttons are placed. Optionally there is a status line below the row of buttons.

The dialog is modal by default.

=head2 Example

Example use of the class B<GnomeTools::Gtk::Dialog>.

  method make-dialog ( ) {
    my Str $dialog-header = Q:a:to/EOHEADER/;
      This is a small test to show a dialog with an entry
      and a few buttons. The <b>Hello</b> button shows some
      text in the statusbar when pressed. The <b>Cancel</b>
      button stops the program.
      EOHEADER

    with my Gnome::Gtk4::Entry $entry .= new-entry {
      .set-placeholder-text('Text shows up after pressing Hello');
      .set-size-request( 400, -1);
    }

    with my GnomeTools::Gtk::Dialog $dialog .= new(
      :$dialog-header, :dialog-title('Test Dialog'), :add-statusbar
    ) {
      .add-content( 'Please enter your name', $entry);
      .add-button( helper.new, 'say-hello', 'Hello', :$dialog, :$entry);
      .add-button( $dialog, 'destroy-dialog', 'Cancel');
    }
  }
  …
  method say-hello (
    GnomeTools::Gtk::Dialog :$dialog,
    Gnome::Gtk4::Entry :$entry
  ) {
    say "hello $entry.get-text()";
    $dialog.set-status("hello <b>$entry.get-text()\</b>");
  }
  …

=head2 Css

The Css classes defined for the B<GnomeTools::Gtk::Dialog> are; C<dialog-tool>, C<dialog-header>, C<dialog-content>, and C<dialog-button>.

When the following code is added to method C<make-dialog()>

=begin code
  my GnomeTools::Gtk::Theming $theme .= new(:css-text(Q:q:to/EOCSS/));
  .dialog-tool {
    background-color: #afafaf;
  }

  .dialog-header {
    color:rgb(59, 1, 65);
    padding-left: 15px;
    padding-right: 15px;
  }

  .dialog-content label {
    color: #004060;
  }

  .dialog-button label {
    color:rgb(15, 165, 240);
  }

  .statusbar-tool {
    background-color:rgb(84, 10, 85);
    border-width: 5px;
    border-style: groove;
    border-color:rgb(144, 0, 255);
  }

  .statusbar-tool > label {
    color:rgb(0, 0, 90);
  }

  .dialog-entry {
    border-width: 5px;
    border-style: inset;
    border-color:rgb(144, 0, 255);
    color:rgb(255, 141, 141);
  }

  EOCSS

  $theme.add-css-class( $entry, 'dialog-entry');

=end code

The status bar has its own css classes as is shown in the code. Also the emtry widget got a class C<dialog-entry>. The result shows like;

=for image :src<asset_files/images/Dialog-2.png> :width<60%> :class<inline>

=end pod


unit class GnomeTools::Gtk::Dialog:auth<github:MARTIMM>;
also is Gnome::Gtk4::Window;

has Gnome::Gtk4::Grid $!content;
has GnomeTools::Gtk::Theming $!theme;

has Int $!content-count;

has Gnome::Gtk4::Box $!button-row;
has GnomeTools::Gtk::Statusbar $!statusbar;
has Gnome::Glib::N-MainLoop $!main-loop;

#-------------------------------------------------------------------------------
method new ( |c ) {
#note "$?LINE ", c.gist;
  self.new-window(|c);
}

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=head2 new

Create a B<GnomeTools::Gtk::Dialog>.

=begin code
submethod BUILD (
  Str :$dialog-header = '',  Str :$dialog-title = '',
  Bool :$add-statusbar = False, Gnome::Gtk4::Window :$transition-window?,
  Int :$width = 400, :$height = 100, Bool :$modal = True
)
=end code
=item $dialog-header; A small text placed at the top of the dialog.
=item $dialog-title; A string placed in the windows decoration bar.
=item $add-statusbar; A statusbar can be placed at the bottom of the dialog. Not shown by default.
=item $transition-window; Make the dialog depending on another window. This is useful that the dialog also is destroyed when the $transition-window is removed.
=item $width; The width of the dialog.
=item $heaght; The width of the dialog.
=item $modal; Specifies that other windows cannot get focus when $modal is True. Turned on by default.
=end pod

submethod BUILD (
  Str :$dialog-header = '',  Str :$dialog-title = '',
  Bool :$add-statusbar = False, Gnome::Gtk4::Window :$transition-window?,
  Int :$width = 400, :$height = 100, Bool :$modal = True
) {
  $!main-loop .= new-mainloop( N-Object, True);
  $!theme .= new;

  $!content-count = 0;
  with $!content .= new-grid {
    .set-margin-top(20);
    .set-margin-bottom(20);
    .set-margin-start(20);
    .set-margin-end(20);

    .set-row-spacing(10);
    .set-column-spacing(20);
    .set-hexpand(True);

    $!theme.add-css-class( $!content, 'dialog-content');
  }

  # Make a button box with horizontal layout
  with $!button-row .= new-box( GTK_ORIENTATION_HORIZONTAL, 4) {
    .set-margin-end(10);
  }

  # Make a label which wil push all buttons to the left. These are
  # added using add-button()
  with my Gnome::Gtk4::Label $button-row-strut .= new-label {
    .set-text(' ');
    .set-halign(GTK_ALIGN_FILL);
    .set-hexpand(True);
    .set-wrap(False);
    .set-visible(True);
  }
  $!button-row.append($button-row-strut);
  $!statusbar .= new if $add-statusbar;

  with my Gnome::Gtk4::Label $header .= new-label {
    .set-markup($dialog-header);
    $!theme.add-css-class( $header, 'dialog-header');
  }

  with my Gnome::Gtk4::Box $box .= new-box( GTK_ORIENTATION_VERTICAL, 0) {
    .append($header);
    .append($!content);
    .append($!button-row);
    .append($!statusbar) if $add-statusbar;
  }

  with self {
    $!theme.add-css-class( self, 'dialog-tool');
    .set-transient-for($transition-window) if ?$transition-window;
    .set-destroy-with-parent(True);
    .set-modal($modal);
    .set-size-request( $width, $height);
    .set-title($dialog-title);
    .register-signal( self, 'destroy-dialog', 'close-request');
    .set-child($box);
  }
}

#-------------------------------------------------------------------------------
=begin pod
=head2 add-content

Content is added to the dialog. There is always a label on the left and a user defined widget on the right.

=begin code
method add-content (
  Str:D $text, *@widgets, Int :$columns = 1, Int :$rows = 1
)
=end code
=item $text; The text shown on the left
=item *@widgets; One or more widgets placed horizontally
=item $columns; The number of columns each widget needs. By default 1.
=item $rows; The number of rows each widget needs. By default 1.
=end pod
multi method add-content (
  Str:D $text, *@widgets, Int :$columns = 1, Int :$rows = 1
) {
  my Int $column = 0;
  $!content.attach(
    self!make-content-label($text), $column++, $!content-count, 1, 1
  );

  for @widgets -> $widget {
    $widget.set-hexpand(True);
    $!content.attach( $widget, $column, $!content-count, $columns, $rows);
    $column += $columns;
  }

  $!content-count += $rows;
}

#-------------------------------------------------------------------------------
multi method add-content ( Str:D $text, Array:D $widgets, Int :$rows = 1 ) {
  my Int $column = 0;
  $!content.attach(
    self!make-content-label($text), $column++, $!content-count, 1, 1
  );

  for @$widgets -> Int $columns, $widget {
    $widget.set-hexpand(True);
    $!content.attach( $widget, $column, $!content-count, $columns, $rows);
    $column += $columns;
  }

  $!content-count += $rows;
}

#-------------------------------------------------------------------------------
method !make-content-label ( Str $text --> Gnome::Gtk4::Label ) {
  with my Gnome::Gtk4::Label $label .= new-label {
    .set-text($text);
#    .set-hexpand(True);
    .set-halign(GTK_ALIGN_START);
    .set-valign(GTK_ALIGN_START);
    .set-margin-end(5);
  }

  $label
}

#-------------------------------------------------------------------------------
method add-button ( Mu $object, Str $method, Str $button-label, *%options ) {
  my Gnome::Gtk4::Button $button .= new-button;
  $button.set-label($button-label);
  $button.register-signal( $object, $method, 'clicked', |%options);
  $!button-row.append($button);
  $!theme.add-css-class( $button, 'dialog-button');
}

#-------------------------------------------------------------------------------
method set-status ( Str $message ) {
  if ?$!statusbar {
    $!statusbar.set-status($message);
  }

  else {
    note "No statusbar defined, use :add-statusbar option";
  }
}

#-------------------------------------------------------------------------------
method show-dialog ( ) {
  self.set-visible(True);
  self.present;
  $!main-loop.run;
}

#-------------------------------------------------------------------------------
method destroy-dialog ( ) {
  $!main-loop.quit;
  self.destroy;
  self.clear-object;
}
