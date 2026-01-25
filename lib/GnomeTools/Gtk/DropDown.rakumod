
use v6.d;
use NativeCall;

#TODO add css classnames
#TODO also make use of ObjectList to add widgets instead of strings only

use Gnome::Gtk4::DropDown:api<2>;
use Gnome::Gtk4::T-types:api<2>;
use Gnome::Gtk4::SingleSelection:api<2>;

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

There is only one css class defined. It is called C<dropdown-tool>.

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
submethod BUILD ( )
=end code

=end pod

submethod BUILD () {

  $!theme .= new;
  $!theme.add-css-class( self, 'dropdown-tool');

  self!init(:!multi-select);
  self.set-model($!selection-type);
  self.set-factory($!signal-factory);
#  self.set-list-factory($!signal-factory);
#  self.set-header-factory($!signal-factory);

  self.set-show-arrow(True);
}

#-------------------------------------------------------------------------------
method set-selection-changed ( Any:D :$object, Str:D :$method, *%options ) {
  self.register-signal(
    self, 'this-selection-changed', 'notify::selected',
    :$object, :$method, |%options
  );
}

#-------------------------------------------------------------------------------
method this-selection-changed ( N-Object $, :$object, :$method, *%options ) {
  $object."$method"(|%options);
}

#-------------------------------------------------------------------------------
=begin pod
=head2 select

Select an entry to be shown from the dropdown list.

=begin code
method select ( Str:D $select-item )
=end code
=item $select-item; The item to be selected.

=end pod

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
=begin pod
=head2 get-text

Get the text of the currently selected item.

=begin code
method get-text ( --> Str )
=end code
=end pod

method get-text ( --> Str ) {
  my UInt $p = self.get-selected;
  $p == GTK_INVALID_LIST_POSITION ?? '' !! $!list-objects.get-string($p);
}
