use v6.d;

use NativeCall;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;
use Gnome::N::X:api<2>;
#Gnome::N::debug(:on);

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

#-------------------------------------------------------------------------------
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
# Only for default callback work
method !set-events ( ) {

  # See also https://docs.gtk.org/gtk4/class.SignalListItemFactory.html
  with $!signal-factory {
    .register-signal( self, 'setup', 'setup');

    .register-signal( self, 'bind', 'bind');

    # unbind doesn't need a default
    #.register-signal( self, 'unbind', 'unbind');

    .register-signal( self, 'teardown', 'teardown');
  }
}

#-------------------------------------------------------------------------------
method set-setup ( Any :$object, Str :$method, *%options ) {
  $!signal-factory.register-signal(
    self, 'setup', 'setup', :$object, :$method, |%options
  );
}

#-------------------------------------------------------------------------------
method set-bind ( Any :$object, Str :$method, *%options ) {
  $!signal-factory.register-signal(
    self, 'bind', 'bind', :$object, :$method, |%options
  );
}

#-------------------------------------------------------------------------------
method set-unbind ( Any:D :$object, Str:D :$method, *%options ) {
  $!signal-factory.register-signal(
    self, 'unbind', 'unbind', :$object, :$method, |%options
  );
}

#-------------------------------------------------------------------------------
method set-teardown ( Any :$object, Str :$method, *%options ) {
  $!signal-factory.register-signal(
    self, 'teardown', 'teardown', :$object, :$method, |%options
  );
}

#-------------------------------------------------------------------------------
method set-selection-changed ( Any:D :$object, Str:D :$method, *%options ) {
  $!selection-type.register-signal(
    self, 'selection-changed', 'selection-changed',
    :$object, :$method, |%options
  )
}

#-------------------------------------------------------------------------------
# Method called with list items from ListModel after a setup event.
# Purpose of this call is to make a widget without any values. This widget
# is placed in the list item. Later, on bind event, the values must be filled
# in.
method setup (
  Gnome::Gtk4::ListItem() $list-item, :$object, Str :$method, *%options
) {
  # If object and method exists, call the method to let the widget
  # be created by the user.
  if ?$object and $object.^can($method) {
    my Gnome::Gtk4::Widget $widget = $object."$method"(|%options);
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
method bind (
  Gnome::Gtk4::ListItem() $list-item, :$object, Str :$method, *%options
) {

  my Gnome::Gtk4::StringObject $string-object .=  new(
    :native-object($list-item.get-item)
  );
  my Str $text = $string-object.get-string;

  # If object and method exists, call the method to let the widget
  # be filled in by the user.
  if ?$object and $object.^can($method) {
    $object."$method"( $list-item.get-child, $text, |%options);
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
method unbind (
  Gnome::Gtk4::ListItem() $list-item, :$object, Str :$method, *%options
) {
  my Gnome::Gtk4::StringObject $string-object;
  $string-object .=  new(:native-object($list-item.get-item));
  my Str $text = $string-object.get-string;
  $object."$method"( $list-item.get-child, $text, |%options);
}

#-------------------------------------------------------------------------------
# When teardown event fires, the listview wants to remove the widget entirely.
method teardown (
  Gnome::Gtk4::ListItem() $list-item, :$object, Str :$method, *%options
) {
  if ?$object and $object.^can($method) {
    $object."$method"( $list-item.get-child, |%options);
  }

  else {
    my Label() $label = $list-item.get-child;
    $label.clear-object;
  }
}

#-------------------------------------------------------------------------------
method selection-changed (
  UInt $position, UInt $n-items, :$object, :$method, *%options
) {
  $object."$method"( $position, self.get-selection, |%options);
}

#-------------------------------------------------------------------------------
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
method append ( *@list-item ) {
  for @list-item -> $list-item {
    $!list-objects.append($list-item);
  }
}

#-------------------------------------------------------------------------------
# find() not yet available. only after 4.18
method find ( Str $list-item --> UInt ) {
  $!list-objects.find($list-item);
}

#-------------------------------------------------------------------------------
method get-string ( UInt $pos --> Str ) {
  $!list-objects.get-string($pos);
}

#-------------------------------------------------------------------------------
method remove ( UInt $pos ) {
  $!list-objects.remove($pos);
}

#-------------------------------------------------------------------------------
method splice ( UInt $pos, UInt $nremove, @str-array ) {
  my $array = CArray[Str].new( |@str-array, Str);
  $!list-objects.splice( $pos, $nremove, $array);
}
