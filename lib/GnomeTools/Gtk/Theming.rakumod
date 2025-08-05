use v6.d;

use Gnome::Gtk4::StyleContext:api<2>;
use Gnome::Gtk4::CssProvider:api<2>;
use Gnome::Gtk4::T-styleprovider:api<2>;
use Gnome::Gtk4::Widget:api<2>;

use Gnome::Gdk4::Display:api<2>;

use Gnome::N::N-Object:api<2>;

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::Theming;

my Gnome::Gtk4::CssProvider $css-provider;

#-------------------------------------------------------------------------------
multi submethod BUILD ( Str:D :$css-path ) {
  self.check-provider;
  $css-provider.load-from-path($css-path);
}

#-------------------------------------------------------------------------------
multi submethod BUILD ( Str:D :$css-text ) {
  self.check-provider;
  $css-provider.load-from-string($css-text);
}

#-------------------------------------------------------------------------------
method add-css-class ( Gnome::Gtk4::Widget $context, Str:D $css-class ) {
  self.check-provider;

  my Gnome::Gdk4::Display() $display .= new;
  $display .= get-default;
  
  my Gnome::Gtk4::StyleContext $style-context .= new;
  $style-context.add-provider-for-display(
    $display, $css-provider, GTK_STYLE_PROVIDER_PRIORITY_USER
  );

  $context.add-css-class($css-class);
}

#-------------------------------------------------------------------------------
method check-provider ( ) {
  $css-provider .= new-cssprovider unless ?$css-provider;
}


