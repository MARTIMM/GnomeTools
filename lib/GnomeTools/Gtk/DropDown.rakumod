
use v6.d;
use NativeCall;

#TODO add css classnames
#TODO also make use of ObjectList to add widgets instead of strings only

use Gnome::Gtk4::DropDown:api<2>;
#use Gnome::Gtk4::StringList:api<2>;
use Gnome::Gtk4::T-types:api<2>;
#use Gnome::Gtk4::SignalListItemFactory:api<2>;
#use Gnome::Gtk4::SingleSelection:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;
#use Gnome::N::X:api<2>;
#Gnome::N::debug(:on);

use GnomeTools::Gtk::Theming;
use GnomeTools::Gtk::R-ListModel;

#-------------------------------------------------------------------------------
=begin pod
=TITLE GnomeTools::Gtk::DropDown
=head1 Description


=end pod

unit class GnomeTools::Gtk::DropDown:auth<github:MARTIMM>;
also is Gnome::Gtk4::DropDown;
also does GnomeTools::Gtk::R-ListModel;

has GnomeTools::Gtk::Theming $!theme;

#has Gnome::Gtk4::StringList $!list-objects;
#has Gnome::Gtk4::SignalListItemFactory $!signal-factory;
#has Gnome::Gtk4::SingleSelection $!selection-type;

#-------------------------------------------------------------------------------
method set-events ( :$object, *%options ) {
  $!list-objects .= new-stringlist(CArray[Str].new(Str)) unless ?$!list-objects;
  self.register-signal(
    self, 'selection-changed-notify', 'notify::selected', :$object, |%options
  ) if ?$object and $object.^can('selection-changed');
}

#-------------------------------------------------------------------------------
multi method new ( N-Object() $model, N-Object() $expression, |c ) {
  self.new-dropdown( $model, $expression);
}

#-------------------------------------------------------------------------------
multi method new ( |c ) {
  self.new-dropdown( N-Object, N-Object, |c);
}

#-------------------------------------------------------------------------------
# Initialize from main page
#submethod BUILD ( :$object, *%options ) {
submethod BUILD ( ) {

  $!theme .= new;
  $!theme.add-css-class( self, 'dropdown-tool');

  $!list-objects .= new-stringlist(CArray[Str].new(Str));
  self.set-model($!list-objects);

# No factory! default is ok. also shows mark of selection when list is visible
#  self.set-factory($!signal-factory);
#  self.set-list-factory($!signal-factory);
#  self.set-header-factory($!signal-factory);

  self.set-show-arrow(True);
}

#-------------------------------------------------------------------------------
method select ( Str:D $select-item ) {
#  my Gnome::Gtk4::StringList() $stringlist = self.get-model;
  for ^$!list-objects.get-n-items -> $index {
    if $!list-objects.get-string($index) eq $select-item {
      self.set-selected($index);
      last;
    }
  }
}

#-------------------------------------------------------------------------------
method get-text ( --> Str ) {
#say Backtrace.new.nice;
#  my Gnome::Gtk4::StringList() $stringlist = self.get-model;
  my UInt $p = self.get-selected;

  my Str $s = '';
  $s = $!list-objects.get-string($p) unless $p == GTK_INVALID_LIST_POSITION;

  $s
}

=finish
