use v6.d;

use NativeCall;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;
use Gnome::N::X:api<2>;
#Gnome::N::debug(:on);

#use Gnome::Gtk4::ListView:api<2>;
use Gnome::Gtk4::ListItem:api<2>;
use Gnome::Gtk4::SignalListItemFactory:api<2>;
use Gnome::Gtk4::StringList:api<2>;
use Gnome::Gtk4::StringObject:api<2>;
use Gnome::Gtk4::SingleSelection:api<2>;
use Gnome::Gtk4::MultiSelection:api<2>;
use Gnome::Gtk4::ScrolledWindow:api<2>;
use Gnome::Gtk4::Label:api<2>;
use Gnome::Gtk4::T-enums:api<2>;
use Gnome::Gtk4::N-Bitset:api<2>;

#use Method::Also;

#-------------------------------------------------------------------------------
=begin pod
=TITLE GnomeTools::Gtk::R-ListModel
=head1 Description

Role to be used for List objects such as B<GnomeTools::Gtk::ListView>. 

=end pod

unit role GnomeTools::Gtk::R-ListModel;

has Gnome::Gtk4::StringList $!list-objects;
has $!selection-type;
has Gnome::Gtk4::SignalListItemFactory $!signal-factory;

#-------------------------------------------------------------------------------
# Init called from role users like GnomeTools::Gtk::ListView to
# initialize 
method !init ( Bool :$multi-select = False ) {
  $!list-objects .= new-stringlist(CArray[Str].new(Str));

  $!selection-type = $multi-select
    ?? Gnome::Gtk4::MultiSelection.new-multiselection($!list-objects)
    !! Gnome::Gtk4::SingleSelection.new-singleselection($!list-objects);

  $!signal-factory .= new-signallistitemfactory;
}

#-------------------------------------------------------------------------------
method !set-events ( :$object, *%options ) {

  my $callframe = callframe(1);
note "$?LINE ", $callframe.code.gist.Str;
note "$?LINE ", $callframe.code.^name;
note "$?LINE ", $callframe.code.package.^name;

  # A DropDown has different events to cope with
  if $callframe.code.gist ~~ 'set-events' and
     $callframe.code.package.^name ~~ 'GnomeTools::Gtk::DropDown'
  {
    self.register-signal(
      self, 'selection-changed-notify', 'notify::selected', :$object, |%options
    ) if ?$object and $object.^can('selection-changed');
  }

  else {
    $!selection-type.register-signal(
      self, 'selection-changed', 'selection-changed', :$object, |%options
    ) if ?$object and $object.^can('selection-changed');
  }

  # See also https://docs.gtk.org/gtk4/class.SignalListItemFactory.html
  with $!signal-factory {
    .register-signal( self, 'setup-list-item', 'setup', :$object, |%options);
    .register-signal( self, 'bind-list-item', 'bind', :$object, |%options);
    .register-signal( self, 'unbind-list-item', 'unbind', :$object, |%options)
      if ?$object and $object.^can('unbind-list-item');
    .register-signal(
      self, 'teardown-list-item', 'teardown', :$object, |%options
    );
  }
}

#-------------------------------------------------------------------------------
# Method called with list items from ListModel after a setup event.
# Purpose of this call is to make a widget without any values. This widget
# is placed in the list item. Later, on bind event, the values must be filled
# in.
method setup-list-item (
  Gnome::Gtk4::ListItem() $list-item, :$object, *%options
) {
  # If object and method exists, call the method to let the widget
  # be created by the user.
  if ?$object and $object.^can('setup-list-item') {
    my Gnome::Gtk4::Widget $widget = $object."setup-list-item"(|%options);
    $list-item.set-child($widget);
  }

  # Otherwise make a simple Label widget
  else {
    with my Gnome::Gtk4::Label $label .= new-label {
      .set-hexpand(True);
      .set-justify(GTK_JUSTIFY_LEFT);
      .set-halign(GTK_ALIGN_START);
    }

    $list-item.set-child($label);
  }
}

#-------------------------------------------------------------------------------
# When bind event fires, the listview wants to show the item but must
# be filled first
method bind-list-item (
  Gnome::Gtk4::ListItem() $list-item, :$object, *%options
) {
 
  my Gnome::Gtk4::StringObject $string-object .=  new(
    :native-object($list-item.get-item)
  );
  my Str $text = $string-object.get-string;

  # If object and method exists, call the method to let the widget
  # be filled in by the user.
  if ?$object and $object.^can('bind-list-item') {
    $object."bind-list-item"( $list-item.get-child, $text, |%options);
  }

  else {
    my Gnome::Gtk4::Label() $label = $list-item.get-child;
    $label.set-text($text);
  }

  $string-object.clear-object;
}

#-------------------------------------------------------------------------------
# When unbind event fires, the listview wants to remove the item from display
# and the values must be removed from the widget. A selection of a listview row
# also triggers an unbind, after which a bind follows.
# Checks made in BUILD() prevents calling this method if $object
# and method .unbind-list-item() is not defined.
# There is no need to unbind a Label value.
method unbind-list-item (
  Gnome::Gtk4::ListItem() $list-item, :$object, *%options
) {
  my Gnome::Gtk4::StringObject $string-object;
  $string-object .=  new(:native-object($list-item.get-item));
  my Str $text = $string-object.get-string;
  $object."unbind-list-item"( $list-item.get-child, $text, |%options);
}

#-------------------------------------------------------------------------------
# When teardown event fires, the listview wants to remove the widget entirely.
method teardown-list-item (
  Gnome::Gtk4::ListItem() $list-item, :$object, *%options
) {
  if ?$object and $object.^can('teardown-list-item') {
    $object."teardown-list-item"( $list-item.get-child, |%options);
  }

  else {
    my Label() $label = $list-item.get-child;
    $label.clear-object;
  }
}

#-------------------------------------------------------------------------------
method activate-list-item ( UInt $position, :$object, *%options ) {
  $object.activate-list-item( $position, self.get-selection, |%options);
}

#-------------------------------------------------------------------------------
method selection-changed (
  UInt $position, UInt $n-items, :$object, *%options
) {
  $object.selection-changed( $position, self.get-selection, |%options);
}

#-------------------------------------------------------------------------------
method selection-changed-notify ( N-Object $, :$object, *%options ) {
  $object.selection-changed(|%options);
}

#-------------------------------------------------------------------------------
=begin pod
=head2 get-selection

Get the current selection.

=begin code
method get-selection ( Bool :$rows = False --> List )
=end code

=item $rows: By default a list of items are returned. When row numbers are needed set the variable to True.
=end pod

method get-selection ( Bool :$rows = False --> List ) {

  return () unless ?$!selection-type;

  my @selections = ();
  my Gnome::Gtk4::N-Bitset $bitset .= new(
    :native-object($!selection-type.get-selection)
  );

  my Int $n = $bitset.get-size;
  for ^$n -> $i {
    if $rows {
      @selections.push: $bitset.get-nth($i);
    }

    else {
      @selections.push: $!list-objects.get-string($bitset.get-nth($i));
    }
  }

  @selections
}

#-------------------------------------------------------------------------------
=begin pod
=head2 append

Add an item at the end of the list
=begin code
method append ( Str $list-item )
=end code

=item $list-item: The item to append.
=end pod

method append ( Str $list-item ) {
  $!list-objects.append($list-item);
}

#-------------------------------------------------------------------------------
# find() not yet available. only after 4.18
=begin pod
=head2 find

Gets the position of the item in the list. The return value can be undefined.

=begin code
method find ( Str $list-item --> UInt )
=end code

=item $list-item: The item to find.
=end pod

method find ( Str $list-item --> UInt ) {
  $!list-objects.find($list-item);
}

#-------------------------------------------------------------------------------
=begin pod
=head2 get-string

Gets the item at C<$pos>ition of the item in the list. The return value can be undefined.

=begin code
method get-string ( UInt $pos --> Str )
=end code

=item $pos: The item at the position.
=end pod

method get-string ( UInt $pos --> Str ) {
  $!list-objects.get-string($pos);
}

#-------------------------------------------------------------------------------
=begin pod
=head2 remove

Remove the item at C<$pos>ition of the item in the list.

=begin code
method remove ( UInt $pos )
=end code

=item $pos: The item at the position.

=head3 An example to remove selected items

=begin code
# Reverse rows because after each removal the row count decreases
# This causes to remove wrong rows or throwing errors like:
# (process:8769): Gtk-CRITICAL **: 18:25:48.324: gtk_string_list_splice:
# assertion 'position + n_removals <= objects_get_size (&self->items)'
# failed.
# The error shows that under the hood, splice() is used

my @selections = $listview.get-selection(:rows).reverse;
for @selections -> $selection {
  $listview.remove($selection);
}
=end code
=end pod

method remove ( UInt $pos ) {
  $!list-objects.remove($pos);
}

#-------------------------------------------------------------------------------
=begin pod
=head2 splice

Remove and/or insert items at C<$pos>ition.

=begin code
method splice ( UInt $pos, UInt $nremove, @str-array )
=end code

=item $pos: The item at the position.
=item $nremove: Number of rows to remove at $pos.
=item @str-array: The array of items to insert at $pos after removal.
=end pod

method splice ( UInt $pos, UInt $nremove, @str-array ) {
  my $array = CArray[Str].new( |@str-array, Str);
  $!list-objects.splice( $pos, $nremove, $array);
}
