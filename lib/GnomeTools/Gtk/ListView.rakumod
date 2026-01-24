use v6.d;
use NativeCall;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;
#use Gnome::N::X:api<2>;
#Gnome::N::debug(:on);

use Gnome::Gtk4::ListView:api<2>;
use Gnome::Gtk4::ScrolledWindow:api<2>;
use Gnome::Gtk4::Label:api<2>;
use Gnome::Gtk4::T-enums:api<2>;

use GnomeTools::Gtk::Theming;
use GnomeTools::Gtk::R-ListModel;

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::ListView:auth<github:MARTIMM>;
also is Gnome::Gtk4::ScrolledWindow;
also does GnomeTools::Gtk::R-ListModel;

has GnomeTools::Gtk::Theming $!theme;
has Gnome::Gtk4::ListView $!list-view;

#-------------------------------------------------------------------------------
method new ( |c ) {
  self.new-scrolledwindow(|c);
}

#-------------------------------------------------------------------------------
submethod BUILD (
  Bool :$multi-select = False, :$orientation = GTK_ORIENTATION_VERTICAL
) {
  $!theme .= new;
  $!theme.add-css-class( self, 'listview-window');

  self.set-halign(GTK_ALIGN_FILL);
  self.set-vexpand(True);
  self.set-propagate-natural-width(True);

  self!init(:$multi-select);

  with $!list-view .= new-listview( N-Object, N-Object) {
    .set-orientation($orientation);
    
    .set-model($!selection-type);
    .set-factory($!signal-factory);
    .set-enable-rubberband(True);
    .set-show-separators(True);

    $!theme.add-css-class( $!list-view, 'listview-tool');
  }

  self.set-child($!list-view);
}

#-------------------------------------------------------------------------------
method set-events ( :$object, *%options ) {
  self!set-events( :$object, |%options);
}

#-------------------------------------------------------------------------------
method set-activate( :$object, *%options ) {
  $!list-view.register-signal(
    self, 'activate-list-item', 'activate', :$object, |%options
  ) if ?$object and $object.^can('activate-list-item');
}

#-------------------------------------------------------------------------------
method activate-list-item ( UInt $position, :$object, *%options ) {
  $object.activate-list-item( $position, self.get-selection, |%options);
}
