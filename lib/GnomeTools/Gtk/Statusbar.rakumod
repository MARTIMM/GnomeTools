use v6.d;

use Gnome::Gtk4::Label:api<2>;
use Gnome::Gtk4::T-enums:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;

use GnomeTools::Gtk::Theming;

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::Statusbar:auth<github:MARTIMM>;
also is Gnome::Gtk4::Label;

#-------------------------------------------------------------------------------
has GnomeTools::Gtk::Theming $!theme;

#-------------------------------------------------------------------------------
method new ( |c ) {
  self.new-label(|c);
}

#-------------------------------------------------------------------------------
submethod BUILD ( ) {
  $!theme .= new;

  with self {
    .set-text('');

    .set-halign(GTK_ALIGN_FILL);
    .set-hexpand(True);
    .set-xalign(0);

    .set-wrap(False);
    .set-visible(True);

    .set-margin-top(10);
    .set-margin-bottom(10);
    .set-margin-start(5);
    .set-margin-end(5);

    $!theme.add-css-class( self, 'statusbar-tool');
  }
}

#-------------------------------------------------------------------------------
method set-status ( Str $text ) {
  self.set-markup($text);
}
