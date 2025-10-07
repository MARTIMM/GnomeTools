use v6.d;

use NativeCall;

use Gnome::Gio::Menu:api<2>;
use Gnome::Gio::MenuItem:api<2>;
use Gnome::Gio::SimpleAction:api<2>;

use Gnome::Gtk4::Application:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;

#-------------------------------------------------------------------------------
class GnomeTools::Gtk::Menu::Menubar {
  has Gnome::Gio::Menu $.menubar;
  has Gnome::Gtk4::Application $.application is required;

  #-----------------------------------------------------------------------------
  submethod BUILD ( Gnome::Gtk4::Application:D :$!application ) {
    $!menubar .= new-menu;
  }

  method add-menu ( Gnome::Gio::Menu:D $menu, $menu-name ) {
    $!menubar.append-submenu( $menu-name, $menu);
  }

  method get-menu ( --> GnomeTools::Gtk::Menu::Menubar ) {
    self
  }
}

#-------------------------------------------------------------------------------
class GnomeTools::Gtk::Menu::Menu {
  has Gnome::Gio::Menu $!menu;

  #-----------------------------------------------------------------------------
  submethod BUILD (
    :$parent-menu where $parent-menu.^lookup('get-menu').defined,
    Str:D :$name
  ) {
    $!menu .= new-menu;
    $parent-menu.get-menu.add-menu( $!menu, $name);
  }

  method get-menu ( --> Gnome::Gio::Menu ) {
    $!menu
  }
}

#-------------------------------------------------------------------------------
class GnomeTools::Gtk::Menu::Section {
  has Gnome::Gio::Menu $!section-menu;

  #-----------------------------------------------------------------------------
  submethod BUILD (
    :$parent-menu where $parent-menu.^lookup('get-menu').defined
  ) {
    $!section-menu .= new-menu;
  }

  method get-menu ( --> Gnome::Gio::Menu ) {
    $!section-menu
  }
}

#-------------------------------------------------------------------------------
class GnomeTools::Gtk::Menu::Item {
  has Gnome::Gio::Menu $!menu-item;

  #-----------------------------------------------------------------------------
  submethod BUILD (
    :$parent-menu where $parent-menu.^lookup('get-menu').defined,
    Str:D :$name, Mu :$object, Str :$method
  ) {
    my Gnome::Gio::Menu $menu = $parent-menu.get-menu;
    my Str $action-name = 'app.' ~ $method;

    # Make a menu entry
    my Gnome::Gio::MenuItem $menu-item .= new-menuitem( $name, $action-name);
    $menu.append-item($menu-item);

    # Use the method name
    my Gnome::Gio::SimpleAction $action .= new-simpleaction( $method, gpointer);
#    $!application.add-action($action);
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
