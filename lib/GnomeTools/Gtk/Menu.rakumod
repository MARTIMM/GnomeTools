use v6.d;

use NativeCall;

use Gnome::Gio::Menu:api<2>;
use Gnome::Gio::MenuItem:api<2>;
use Gnome::Gio::SimpleAction:api<2>;

use Gnome::Gtk4::Application:api<2>;

use Gnome::Glib::T-varianttype:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::Menu;

has Gnome::Gio::Menu $!menu;
has Gnome::Gio::Menu $!parent-menu;
my Array $actions = [];

#-------------------------------------------------------------------------------
multi submethod BUILD (  ) {
  $!menu .= new-menu;
}

#-------------------------------------------------------------------------------
multi submethod BUILD ( GnomeTools::Gtk::Menu :$parent-menu, Str:D :$name! ) {
  $!menu .= new-menu;
  if ?$parent-menu and ?$name {
    $!parent-menu = $parent-menu.get-menu;
    $!parent-menu.append-submenu( $name, $!menu);
  }
}

#-------------------------------------------------------------------------------
multi submethod BUILD ( GnomeTools::Gtk::Menu :$parent-menu, Str :$section! ) {
  $!menu .= new-menu;
  if ?$parent-menu {
    $!parent-menu = $parent-menu.get-menu;
    $!parent-menu.append-section( $section, $!menu);
  }
}

#-------------------------------------------------------------------------------
multi submethod BUILD (
  GnomeTools::Gtk::Menu :$parent-menu, Str:D :$subname!
) {
  $!menu .= new-menu;
  if ?$parent-menu and ?$subname {
    $!parent-menu = $parent-menu.get-menu;
    $!parent-menu.append-submenu( $subname, $!menu);
  }
}

#-------------------------------------------------------------------------------
method get-menu ( --> Gnome::Gio::Menu ) {
  $!menu
}

#-------------------------------------------------------------------------------
method item (
  Str:D $name, Mu:D $object, Str:D $method, Bool :$checkbox = False,
  *%options
) {
  my Str $action-name = 'app.' ~ $method;

  # Make a menu entry
  my Gnome::Gio::MenuItem $menu-item .= new-menuitem( $name, $action-name);

  $!menu.append-item($menu-item);

  # Use the method name
  my Gnome::Gio::SimpleAction $action;
  $action .= new-simpleaction( $method, gpointer);

  $action.register-signal( $object, $method, 'activate', :$action, |%options);
  $actions.push: $action;
}

#-------------------------------------------------------------------------------
method set-actions ( Gnome::Gtk4::Application:D $application ) {
  for @$actions -> $action {
    $application.add-action($action);
  }

  $actions = [];
}
