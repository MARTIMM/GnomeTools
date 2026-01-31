use v6.d;
use NativeCall;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;
#use Gnome::N::X:api<2>;
#Gnome::N::debug(:on);

use Gnome::Gtk4::GridView:api<2>;
use Gnome::Gtk4::ScrolledWindow:api<2>;
use Gnome::Gtk4::Label:api<2>;
use Gnome::Gtk4::T-enums:api<2>;

use GnomeTools::Gtk::Theming;
use GnomeTools::Gtk::R-ListModel;

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::GridView:auth<github:MARTIMM>;
also is Gnome::Gtk4::ScrolledWindow;
also does GnomeTools::Gtk::R-ListModel;

has GnomeTools::Gtk::Theming $!theme;
has Gnome::Gtk4::GridView $!gridview;

#-------------------------------------------------------------------------------
method new ( |c ) {
  self.new-scrolledwindow(|c);
}

#-------------------------------------------------------------------------------
submethod BUILD (
  Bool :$multi-select = False, :$orientation = GTK_ORIENTATION_VERTICAL,
  UInt :$min-columns, UInt :$max-columns
) {
  $!theme .= new;
  $!theme.add-css-class( self, 'gridview-window');

  self.set-halign(GTK_ALIGN_FILL);
  self.set-vexpand(True);
  self.set-propagate-natural-width(True);

  self!init(:$multi-select);

  with $!gridview .= new-gridview( N-Object, N-Object) {
    .set-orientation($orientation);
    .set-min-columns($min-columns) if ?$min-columns;
    .set-max-columns($max-columns) if ?$max-columns;
    
    .set-model($!selection-type);
    .set-factory($!signal-factory);
    .set-enable-rubberband(True);
#    .set-show-separators(True);

    $!theme.add-css-class( $!gridview, 'gridview-tool');
  }

  self.set-child($!gridview);
}

#-------------------------------------------------------------------------------
method set-activate( Any:D $object, Str:D $method, *%options ) {
  $!gridview.register-signal(
    self, 'activate-list-item', 'activate', :$object, :$method, |%options
  )
}

#-------------------------------------------------------------------------------
# callback private
method activate-list-item (
  UInt $position, :$object, Str :$method, *%options
) {
  $object."$method"( $position, self.get-selection, |%options);
}
