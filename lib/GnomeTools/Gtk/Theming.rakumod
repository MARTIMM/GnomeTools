use v6.d;

use Gnome::Gtk4::StyleContext:api<2>;
use Gnome::Gtk4::CssProvider:api<2>;
use Gnome::Gtk4::T-styleprovider:api<2>;

use Gnome::N::N-Object:api<2>;

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::Theming;

has Gnome::Gtk4::CssProvider $!css-provider;

#-------------------------------------------------------------------------------
submethod BUILD ( Str:D :$css-path ) {
  $!css-provider .= new-cssprovider;
  $!css-provider.load-from-path($css-path);
}

#-------------------------------------------------------------------------------
submethod BUILD ( Str:D :$css-text ) {
  $!css-provider .= new-cssprovider;
  $!css-provider.load-from-string($css-text);
}

#-------------------------------------------------------------------------------
method set-css ( N-Object $context, Str:D $css-class ) {
  return unless ?$css-class;

  my Gnome::Gtk4::StyleContext $style-context .= new(:native-object($context));
  $style-context.add-provider(
    $!css-provider, GTK_STYLE_PROVIDER_PRIORITY_USER
  );
  $style-context.add-class($css-class);
}



