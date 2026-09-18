use v6.d;

use Gnome::Gtk4::StyleContext:api<2>;
use Gnome::Gtk4::CssProvider:api<2>;
use Gnome::Gtk4::N-CssSection:api<2>;
use Gnome::Gtk4::T-csssection:api<2>;
use Gnome::Gtk4::T-csslocation:api<2>;
use Gnome::Gtk4::T-styleprovider:api<2>;
use Gnome::Gtk4::Widget:api<2>;

use Gnome::Gdk4::Display:api<2>;

use Gnome::Glib::N-Error:api<2>;
use Gnome::Glib::T-error:api<2>;

use Gnome::N::N-Object:api<2>;

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::Theming;

my Gnome::Gtk4::CssProvider $css-provider .= new-cssprovider;

#-------------------------------------------------------------------------------
multi submethod BUILD ( ) {
#  self.check-provider;
}

#-------------------------------------------------------------------------------
multi submethod BUILD ( Str:D :$css-path ) {
#  self.check-provider;
  $css-provider.register-signal(
    self, 'log-css-parsing', 'parsing-error'
  );
  $css-provider.load-from-path($css-path);
}

#-------------------------------------------------------------------------------
multi submethod BUILD ( Str:D :$css-text ) {
#  self.check-provider;
  $css-provider.register-signal(
    self, 'log-css-parsing', 'parsing-error'
  );
  $css-provider.load-from-string($css-text);
}

#-------------------------------------------------------------------------------
method add-css-class ( Gnome::Gtk4::Widget $context, Str:D $css-class ) {

  # It may be defined but has it text?
  return unless ?$css-class;

#  self.check-provider;
##`{{
  my Gnome::Gdk4::Display() $display .= new;
  $display .= get-default;

  my Gnome::Gtk4::StyleContext $style-context .= new;
  $style-context.add-provider-for-display(
    $display, $css-provider, GTK_STYLE_PROVIDER_PRIORITY_USER
  );

  $context.add-css-class($css-class);
#}}
#`{{
  my Gnome::Gtk4::StyleContext $style-context .= new(:native-object($context));
  $style-context.add-provider(
    $css-provider, GTK_STYLE_PROVIDER_PRIORITY_USER
  );
  $style-context.add-class($css-class);
}}
}

#-------------------------------------------------------------------------------
method remove-css-class ( Gnome::Gtk4::Widget $context, Str:D $css-class ) {

  # It may be defined but has it text?
  return unless ?$css-class;

#  self.check-provider;
#`{{
  my Gnome::Gdk4::Display() $display .= new;
  $display .= get-default;

  my Gnome::Gtk4::StyleContext $style-context .= new;
  $style-context.add-provider-for-display(
    $display, $css-provider, GTK_STYLE_PROVIDER_PRIORITY_USER
  );

  $context.remove-css-class($css-class);
}}
##`{{
  my Gnome::Gtk4::StyleContext $style-context .= new(:native-object($context));
  $style-context.add-provider(
    $css-provider, GTK_STYLE_PROVIDER_PRIORITY_USER
  );
  $style-context.remove-class($css-class);
#}}
}

#-------------------------------------------------------------------------------
method log-css-parsing ( Gnome::Gtk4::N-CssSection() $section, N-Error() $e ) {

my N-CssLocation() $start-location = $section.get-start-location();
my N-CssLocation() $end-location = $section.get-end-location();
note "CSS error $e.message() starting at line $start-location.lines() " ~
     "and ends at $end-location.lines()";

#note "> $section.get-start-location() - $section.get-end-location()";
}

=finish
#-------------------------------------------------------------------------------
method check-provider ( ) {
  $css-provider .= new-cssprovider unless ?$css-provider;
}


