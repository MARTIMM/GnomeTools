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
submethod BUILD (
  Str :$dialog-header = '',  Str :$dialog-title = '',
  Bool :$add-statusbar = False, Gnome::Gtk4::Window :$transition-window?,
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
    .set-modal(True);
    .set-size-request( 400, 100);
    .set-title($dialog-title);
    .register-signal( self, 'close-dialog', 'destroy');
    .set-child($box);
  }
}

#-------------------------------------------------------------------------------
method add-content (
  Str $text, Mu $widget, Int :$columns = 1, Int :$rows = 1
) {
  with my Gnome::Gtk4::Label $label .= new-label {
    .set-text($text);
    .set-hexpand(True);
    .set-halign(GTK_ALIGN_START);
    .set-margin-end(5);
  }

  $!content.attach( $label, 0, $!content-count, 1, 1);
  $!content.attach( $widget, 1, $!content-count, $columns, $rows);
  $!content-count += $rows;
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
  $!main-loop.run;
}

#-------------------------------------------------------------------------------
method destroy-dialog ( ) {
  $!main-loop.quit;
  self.destroy;
  self.clear-object;
}
