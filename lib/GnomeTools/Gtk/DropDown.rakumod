
use v6.d;
use NativeCall;

#TODO add css classnames
#TODO also make use of ObjectList to add widgets instead of strings only

use Gnome::Gtk4::DropDown:api<2>;
use Gnome::Gtk4::T-types:api<2>;

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

Dropdown class using the Gtk4 dropdown class. This module makes it a bit more easy to handle the Gtk4 class.

=head2 Css

There is only one css class defined. It is called `dropdown-tool`.

=head2 Example

  my @items = <class role method sub submethod for else unit package module>;
  my GnomeTools::Gtk::DropDown $dropdown .= new;
  for @items -> $item {
    $dropdown.append($item);
  }

=end pod

unit class GnomeTools::Gtk::DropDown:auth<github:MARTIMM>;
also is Gnome::Gtk4::DropDown;
also does GnomeTools::Gtk::R-ListModel;

has GnomeTools::Gtk::Theming $!theme;

#`{{
#TODO how to use the $expression
#-------------------------------------------------------------------------------
multi method new ( N-Object() $model, N-Object() $expression, |c ) {
  self.new-dropdown( $model, $expression);
}
}}

#-------------------------------------------------------------------------------
multi method new ( |c ) {
  self.new-dropdown( N-Object, N-Object, |c);
}

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods
=head2 new

Create a new dropdown object.

=begin code
=end code
=end pod

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
method set-events ( :$object, *%options ) {
  $!list-objects .= new-stringlist(CArray[Str].new(Str)) unless ?$!list-objects;
  self.register-signal(
    self, 'selection-changed-notify', 'notify::selected', :$object, |%options
  ) if ?$object and $object.^can('selection-changed');
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
