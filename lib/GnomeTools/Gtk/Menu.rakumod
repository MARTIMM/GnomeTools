use v6.d;

use NativeCall;

use Gnome::Gio::Menu:api<2>;
use Gnome::Gio::MenuItem:api<2>;
use Gnome::Gio::SimpleAction:api<2>;

use Gnome::Gtk4::Application:api<2>;

use Gnome::Glib::T-varianttype:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;

#`{{
#-------------------------------------------------------------------------------
class GnomeTools::Gtk::Menu::Menubar {
  has Gnome::Gio::Menu $.menu;
  has Gnome::Gtk4::Application $.application is required;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Gnome::Gtk4::Application:D :$!application ) {
    $!menu .= new-menu;
  }

  method add-menu ( Gnome::Gio::Menu:D $menu, $menu-name ) {
    $!menu.append-submenu( $menu-name, $menu);
  }

  method get-menu ( --> Gnome::Gio::Menu ) {
    $!menu
  }
}
}}
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
#note "$?LINE $parent-menu.gist, $section.gist()";
  if ?$parent-menu {
    $!parent-menu = $parent-menu.get-menu;
    $!parent-menu.append-section( $section, $!menu);
  }
}

#-------------------------------------------------------------------------------
multi submethod BUILD ( GnomeTools::Gtk::Menu :$parent-menu, Str:D :$subname! ) {
  $!menu .= new-menu;
note "$?LINE $parent-menu.gist, $subname";
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
  if $checkbox {
    $action .= new-stateful( $method, N-VariantType, gpointer);
  }

  else {
    $action .= new-simpleaction( $method, gpointer);
  }
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


=finish

#-------------------------------------------------------------------------------
class GnomeTools::Gtk::Menu::Section {
  has Gnome::Gio::Menu $!menu;

  #-----------------------------------------------------------------------------
  submethod BUILD (
    :$parent-menu where $parent-menu.^lookup('get-menu').defined
  ) {
    $!menu .= new-menu;
    $parent-menu.get-menu.append-section( Str, $!menu);
  }

  method get-menu ( --> Gnome::Gio::Menu ) {
    $!menu
  }
}

#-------------------------------------------------------------------------------
class GnomeTools::Gtk::Menu::Item {
  has Gnome::Gio::Menu $!menu-item;

  #-----------------------------------------------------------------------------
  submethod BUILD (
    :$parent-menu where $parent-menu.^lookup('get-menu').defined,
    Str:D :$name, Mu :$object, Str :$method,
    Gnome::Gtk4::Application:D :$application
  ) {
    my Gnome::Gio::Menu $menu = $parent-menu.get-menu;
    my Str $action-name = 'app.' ~ $method;

    # Make a menu entry
    my Gnome::Gio::MenuItem $menu-item .= new-menuitem( $name, $action-name);
    $menu.append-item($menu-item);

    # Use the method name
    my Gnome::Gio::SimpleAction $action .= new-simpleaction( $method, gpointer);
    $application.add-action($action);
    $action.register-signal( $object, $method, 'activate');
  }
}



=finish
#-------------------------------------------------------------------------------
class GnomeTools::Gtk::Menu {

  #-----------------------------------------------------------------------------
  method make-menu ( ) {
#    Gnome::Gio::Menu $menu .= new-menu;
#    --> Gnome::Gio::Menu
  }

  #-----------------------------------------------------------------------------
  method append-as-section-menu ( ) {
  }

  #-----------------------------------------------------------------------------
  method make-sub-menu ( ) {
  }
}
