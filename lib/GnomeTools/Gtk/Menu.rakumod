use v6.d;

use NativeCall;

use Gnome::Gio::Menu:api<2>;
use Gnome::Gio::MenuItem:api<2>;
use Gnome::Gio::SimpleAction:api<2>;

use Gnome::Gtk4::Application:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::Menu;
also is Gnome::Gio::Menu;

has Gnome::Gio::Menu $!menu-bar;
has Gnome::Gtk4::Application $!application is required;

#-------------------------------------------------------------------------------
method new ( |c ) {
  self.new-menu(|c);
}

#-------------------------------------------------------------------------------
submethod BUILD ( Gnome::Gtk4::Application:D :$!application ) {
}

#-------------------------------------------------------------------------------
method make-menu-item ( ) {
}

#-------------------------------------------------------------------------------
method make-section-menu ( ) {
}

#-------------------------------------------------------------------------------
method make-sub-menu ( ) {
}

#-------------------------------------------------------------------------------
method bind-action (
  Gnome::Gio::Menu $menu, Str $menu-name, Mu $object, Str $entry-name,
  Bool :$shortcut = False
) {

  # Make a method and action name
  my Str $method = [~] $menu-name, ' ', $entry-name;
  $method .= lc;
  $method ~~ s:g/ <[\s/_]>+ /-/;

  my Str $action-name = 'app.' ~ $method;

  # Make a menu entry
  my Gnome::Gio::MenuItem $menu-item .= new-menuitem(
    $shortcut ?? "_$entry-name" !! $entry-name, $action-name
  );
  $menu.append-item($menu-item);

  # Use the method name
  my Gnome::Gio::SimpleAction $action .= new-simpleaction( $method, gpointer);
  $!application.add-action($action);
  $action.register-signal( $object, $method, 'activate');
}
