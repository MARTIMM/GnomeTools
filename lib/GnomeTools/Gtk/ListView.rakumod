use v6.d;
use NativeCall;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;
use Gnome::N::X:api<2>;
#Gnome::N::debug(:on);

use Gnome::Gtk4::ListView:api<2>;
use Gnome::Gtk4::ListItem:api<2>;
use Gnome::Gtk4::SignalListItemFactory:api<2>;
use Gnome::Gtk4::StringList:api<2>;
use Gnome::Gtk4::StringObject:api<2>;
use Gnome::Gtk4::MultiSelection:api<2>;
use Gnome::Gtk4::ScrolledWindow:api<2>;
use Gnome::Gtk4::Label:api<2>;
use Gnome::Gtk4::T-enums:api<2>;
use Gnome::Gtk4::N-Bitset:api<2>;

#TODO add css classnames
use GnomeTools::Gtk::Theming;

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::ListView:auth<github:MARTIMM>;
also is Gnome::Gtk4::ScrolledWindow;

has GnomeTools::Gtk::Theming $!theme;

has Gnome::Gtk4::StringList $!list-objects;
has Gnome::Gtk4::MultiSelection $!multi-select;
has Gnome::Gtk4::SignalListItemFactory $!signal-factory;
has Gnome::Gtk4::ListView $!list-view;

#-------------------------------------------------------------------------------
method new ( |c ) {
  self.new-scrolledwindow(|c);
}

#-------------------------------------------------------------------------------
submethod BUILD ( :$object, *%options ) {
  $!theme .= new;
  $!theme.add-css-class( self, 'listview-tool');

  self.set-halign(GTK_ALIGN_FILL);
  self.set-vexpand(True);
  self.set-propagate-natural-width(True);

  $!list-objects .= new-stringlist(CArray[Str].new(Str));
  $!multi-select .= new-multiselection($!list-objects);
  $!multi-select.register-signal(
    self, 'selection-changed', 'selection-changed', :$object, |%options
  ) if ?$object;

  # See also https://docs.gtk.org/gtk4/class.SignalListItemFactory.html
  with $!signal-factory .= new-signallistitemfactory {
    .register-signal( self, 'setup-list-item', 'setup', :$object);
    .register-signal( self, 'bind-list-item', 'bind', :$object);
    .register-signal( self, 'unbind-list-item', 'unbind', :$object);
    .register-signal(
      self, 'teardown-list-item', 'teardown', :$object
    );
  }

  with $!list-view .= new-listview( N-Object, N-Object) {
    .set-model($!multi-select);
    .set-factory($!signal-factory);
    .set-enable-rubberband(True);
    .set-show-separators(True);
#    .register-signal(
#      self, 'activate-list-item', 'activate', :$object
#    );

    $!theme.add-css-class( $!list-view, 'listview-item');
  }

  self.set-child($!list-view);
#  self.show;
}

#-------------------------------------------------------------------------------
# Method called with list items from ListModel after a setup event.
# Purpose of this call is to make a widget without any values. This widget
# is placed in the list item. Later, on bind event, the values must be filled
# in.
method setup-list-item ( Gnome::Gtk4::ListItem() $list-item, :$object ) {

  # If object and method exists, call the method to let the widget
  # be created by the user.
  if ?$object and $object.^can('setup-list-item') {
    my Gnome::Gtk4::Widget $widget = $object."setup-list-item"($list-item);
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
method bind-list-item ( Gnome::Gtk4::ListItem() $list-item, :$object ) {
 
  my Gnome::Gtk4::StringObject $string-object .=  new(
    :native-object($list-item.get-item)
  );
  my Str $text = $string-object.get-string;

  # If object and method exists, call the method to let the widget
  # be filled in by the user.
  if ?$object and $object.^can('bind-list-item') {
    $object."bind-list-item"( $list-item, $text);
  }

  else {
    my Gnome::Gtk4::Label() $label = $list-item.get-child;
    $label.set-text($text);
  }
#note "$?LINE bind";
  $string-object.clear-object;
}

#-------------------------------------------------------------------------------
# When unbind event fires, the listview wants to remove the item from display
# and the values must be removed from the widget. A selection of a listview row
# also triggers an unbind, after which a bind follows.
method unbind-list-item ( Gnome::Gtk4::ListItem() $list-item, :$object ) {

  my Gnome::Gtk4::StringObject $string-object .=  new(
    :native-object($list-item.get-item)
  );
  my Str $text = $string-object.get-string;

  if ?$object and $object.^can('unbind-list-item') {
    $object."unbind-list-item"( $list-item, $text);
  }

  # No need to unbind a Label value
  # else { }
}

#-------------------------------------------------------------------------------
# When teardown event fires, the listview wants to remove the widget entirely.
method teardown-list-item ( Gnome::Gtk4::ListItem() $list-item, :$object ) {
note "$?LINE teardown";

  my Gnome::Gtk4::StringObject $string-object .=  new(
    :native-object($list-item.get-item)
  );
  my Str $text = $string-object.get-string;

  if ?$object and $object.^can('unbind-list-item') {
    $object."unbind-list-item"( $list-item, $object);
  }

  # No need to teardown a Label widget
  # else { }
}

#-------------------------------------------------------------------------------
method activate-list-item ( UInt $position ) {
note "$?LINE activate $position";
}

#-------------------------------------------------------------------------------
method selection-changed (
  UInt $position, UInt $n-items, Any:D :$object, *%options
) {
  return unless $object.^can('selection-changed');
  $object.selection-changed( self.get-selection, |%options);
}

#-------------------------------------------------------------------------------
method get-selection ( --> List ) {

  my @selections = ();
  my Gnome::Gtk4::N-Bitset $bitset .= new(
    :native-object($!multi-select.get-selection)
  );

  my Int $n = $bitset.get-size;
  for ^$n -> $i {
    @selections.push: $bitset.get-nth($i)
  }

  @selections
}

#-------------------------------------------------------------------------------
method append ( Str $list-item ) {
  $!list-objects.append($list-item);
}
