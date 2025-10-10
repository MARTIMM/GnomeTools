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
=begin pod
=TITLE GnomeTools::Gtk::Menu
=head1 Description

Purpose of the module is to create a menu quickly. To set a menubar and to make all entries active, it is necessary to have it based on the B<Application> class of Gtk version 4.

=head2 Example
Example use of the class GnomeTools::Gtk::Menu. Assumed is that the application is created and available.

  method app-activate ( ) {
    my GnomeTools::Gtk::Menu $bar .= new;
    my GnomeTools::Gtk::Menu $m1 .= new( :parent-menu($bar), :name<File>);
    $m1.item( 'Quit', self, 'fq');
    my GnomeTools::Gtk::Menu $ms1 .= new( :parent-menu($m1), :section(Str));
    $ms1.item( 'Edit', self, 'ed1');
    $ms1.item( 'Store', self, 'st1');

    my GnomeTools::Gtk::Menu $m2 .= new( :parent-menu($bar), :name<About>);
    $m2.item( 'About Me', self, 'a0');
    my GnomeTools::Gtk::Menu $m3 .= new( :parent-menu($m2), :subname<A2>);
    $m3.item( 'About o1', self, 'o1');
    $m3.item( 'About o2', self, 'o2');

    $bar.set-actions($!application);

    $!application.set-menubar($bar.get-menu);
    $!app-window .= new-applicationwindow($!application);
    $!app-window.set-show-menubar(True);

    $!app-window.present;
  }

  method fq ( N-Object $parameter ) { note "Run fq\()"; }
  method ed1 ( N-Object $parameter ) { note "Run ed1\()"; }
  method st1 ( N-Object $parameter ) { note "Run st1\()"; }
  method a0 ( N-Object $parameter ) { note "Run a0\()"; }
  method o1 ( N-Object $parameter ) { note "Run o1\()"; }
  method o2 ( N-Object $parameter ) { note "Run o2\()"; }

=end pod

unit class GnomeTools::Gtk::Menu;

has Gnome::Gio::Menu $!menu;
has Gnome::Gio::Menu $!parent-menu;
my Array $actions = [];

#-------------------------------------------------------------------------------
=begin pod
=head1 Constructing

There are 4 ways to build a menu.
=item A toplevel menu does not have a 'parent' menu and it serves as a menubar in most cases. So create such is without any options. All other menus have at least parent menu.
=item A second level menu uses a name which will be visible in a menubar.
=item A sub menu is started with a subname option. That name is visible in a menu. Clicking on that name will show the submenu.
=item A section is started with a section option. The name of the section is visible as a header in the parent menu when not empty, otherwise a space is visible. Clicking on that name will show the submenu.

  multi method new()

  multi method new(
    GnomeTools::Gtk::Menu:D :$parent-menu, Str:D :$name!
  )

  multi method new(
    GnomeTools::Gtk::Menu:D :$parent-menu, Str:D :$subname!
  )

  multi method new(
    GnomeTools::Gtk::Menu:D :$parent-menu, Str:D :$section!
  )

=end pod
multi submethod BUILD ( ) {
  $!menu .= new-menu;
}

#-------------------------------------------------------------------------------
multi submethod BUILD ( GnomeTools::Gtk::Menu:D :$parent-menu, Str:D :$name! ) {
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
=begin pod
=head1 Methods
=head2 get-menu

Get the the B<Gnome::Gio::Menu> object. Needed to hand over a menu to another Gtk 4 object like, for example, the B<Gnome::Gtk4::Application>.
=end pod
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
