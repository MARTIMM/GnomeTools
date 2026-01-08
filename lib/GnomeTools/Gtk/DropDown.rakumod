
use v6.d;

#TODO add css classnames
#TODO also make use of ObjectList to add widgets instead of strings only

use Gnome::Gtk4::DropDown:api<2>;
use Gnome::Gtk4::StringList:api<2>;
use Gnome::Gtk4::T-types:api<2>;
use Gnome::Gtk4::SignalListItemFactory:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;
use Gnome::N::X:api<2>;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
=begin pod
=TITLE GnomeTools::Gtk::DropDown
=head1 Description


=end pod

unit class GnomeTools::Gtk::DropDown:auth<github:MARTIMM>;
also is Gnome::Gtk4::DropDown;

has Gnome::Gtk4::StringList $!list-objects;
has Gnome::Gtk4::SignalListItemFactory $!signal-factory;

#-------------------------------------------------------------------------------
multi method new ( N-Object() $model, N-Object() $expression, |c ) {
  self.new-dropdown( $model, $expression);
}

#-------------------------------------------------------------------------------
multi method new ( |c ) {
  self.new-dropdown( N-Object, N-Object);
}

#-------------------------------------------------------------------------------
# Initialize from main page
submethod BUILD ( ) {

  # Initialize the dropdown object with an empty list
  $!list-objects .= new-stringlist(CArray[Str].new(Str));
  self.set-model($!list-objects);
  $!signal-factory
}

#-------------------------------------------------------------------------------
method set-selection ( @items ) {
  my Gnome::Gtk4::StringList() $stringlist .= new-stringlist([]);
  self.set-model($stringlist);
#  my Int $index = 0;
#  my Bool $index-found = False;

  # Add the container strings
  for @items -> $item {
    $stringlist.append($item);
#    $index-found = True if $item eq $select-item;
#    $index++ unless $index-found;
  }

#  self.set-selected($index-found ?? $index !! 0);
}

#-------------------------------------------------------------------------------
method add-selection ( $item ) {
  my Gnome::Gtk4::StringList() $stringlist = self.get-model;
#  my Int $index = 0;
#  my Bool $index-found = False;

  # Add the container strings
#  for @items -> $item {
    $stringlist.append($item);
#    $index-found = True if $item eq $select-item;
#    $index++ unless $index-found;
#  }

#  self.set-selected($index-found ?? $index !! 0);
}

#-------------------------------------------------------------------------------
method select ( Str:D $select-item ) {
  my Gnome::Gtk4::StringList() $stringlist = self.get-model;
  for ^$stringlist.get-n-items -> $index {
    if $stringlist.get-string($index) eq $select-item {
      self.set-selected($index);
      last;
    }
  }
}

#-------------------------------------------------------------------------------
method get-text ( --> Str ) {
#say Backtrace.new.nice;
  my Gnome::Gtk4::StringList() $stringlist = self.get-model;
  my UInt $p = self.get-selected;

  my Str $s = '';
  $s = $stringlist.get-string($p) unless $p == GTK_INVALID_LIST_POSITION;

  $s
}

#-------------------------------------------------------------------------------
method trap-dropdown-changes (
  Any:D $helper-object, Str:D $method, *%options
) {
  self.register-signal( $helper-object, $method, 'notify::selected', |%options);
}
