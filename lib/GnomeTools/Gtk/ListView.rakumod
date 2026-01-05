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
use Gnome::Gtk4::SingleSelection:api<2>;
use Gnome::Gtk4::MultiSelection:api<2>;
use Gnome::Gtk4::ScrolledWindow:api<2>;
use Gnome::Gtk4::Label:api<2>;
use Gnome::Gtk4::T-enums:api<2>;
use Gnome::Gtk4::N-Bitset:api<2>;

#TODO add css classnames
use GnomeTools::Gtk::Theming;

#-------------------------------------------------------------------------------
=begin pod
=TITLE GnomeTools::Gtk::ListView
=head1 Description

A listview is like a listbox where objects can be inserted horizontally or vertically. The listbox is used for simple and short lists while the listview can be used for much longer lists and complex objects. The listview is filled using a factory and is created in steps. The list is often partly visible and only asks for the objects to be created when they become visible.

There are several events which needs to be captured if complex objects must be created. Other entries are available to get the number of selected items for example.

=head2 CSS classes

The B<GnomeTools::Gtk::ListView> class is placed in a B<Gnome::Gtk4::ScrolledWindow>. That object has a classname C<listview-window> and the B<GnomeTools::Gtk::ListView> object has a classname C<listview-tool> 

=head2 Example

This example shows the easy way to make use of the class. The objects created are simple B<Label> objects with a text.

First define a helper class.
=begin code
class HelperObject {
  method show-select (
    GnomeTools::Gtk::ListView :$listview, GnomeTools::Gtk::Dialog :$dialog,
    :@items
  ) {
    my @selections = @items[$listview.get-selection];
    $dialog.set-status(@selections.join(', '));
  }

  method selection-changed ( @selections, GnomeTools::Gtk::Dialog :$dialog ) {
    $dialog.set-status("Rows '{@selections.join(', ')}' are selected");
  }
}
=end code

Instantiate the class and setup the B<GnomeTools::Gtk::ListView>. In this example the ListView is placed in a B<GnomeTools::Gtk::Dialog>.

=begin code
my HelperObject $helper .= new;

my GnomeTools::Gtk::Dialog $dialog .= new(
  :dialog-header('Test Dialog'), :add-statusbar
);

my @items = <class role method sub submethod for else unit package module>;

my GnomeTools::Gtk::ListView $listview .= new( :object($helper), :$dialog);
for @items -> $item {
  $listview.append($item);
}
$dialog.add-content( 'Nice list', $listview);

# Buttons
$dialog.add-button(
  $helper, 'show-select', 'Get Selection 2',
  :$dialog, :@items, :$listview
);

$dialog.add-button( $dialog, 'destroy-dialog', 'Cancel');

$dialog.set-size-request( 400, 300);
$dialog.show-dialog;
=end code

=end pod

unit class GnomeTools::Gtk::ListView:auth<github:MARTIMM>;
also is Gnome::Gtk4::ScrolledWindow;

has GnomeTools::Gtk::Theming $!theme;

has Gnome::Gtk4::StringList $!list-objects;
has Bool $!multi-select;
has $!selection-type;
has Gnome::Gtk4::SignalListItemFactory $!signal-factory;
has Gnome::Gtk4::ListView $!list-view;

#-------------------------------------------------------------------------------
method new ( |c ) {
  self.new-scrolledwindow(|c);
}

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods

=head2 new

Instanciate the listview class.

=begin code
submethod BUILD ( :$object, Bool :$!multi-select = True, *%options )
=end code

=item $object: User object where methods are defined to process the events. There are many events which can be processed so the method names are fixed for simplicity. The method names are C<selection-changed> for the selection-changed event, C<activate-list-item> for the activate event, C<setup-list-item> to handle the setup event, C<bind-list-item> handles the bind event, C<unbind-list-item> handles the unbind event, and C<teardown-list-item> for the teardown event. The methods are not called when they are not defined.
=item2 Selection type events.
=item3 Method selection-changed; The C<selection-changed> event is emitted when the selection state of some of the items in the model changes.
Note that this signal does not specify the new selection state of the items, they need to be queried manually. It is also not necessary for a model to change the selection state of any of the items in the selection model, though it would be rather useless to emit such a signal. $position is the position of the last clicked selection and @selections is the selection of items used to add items to the list. Any named arguments C<*%options> given to C<.new()> are given to the method.
=begin code
method selection-changed ( UInt $position, @selections, *%options )
=end code

=item2 Events from ListView.
=item3 Method activate-list-item; The C<activate> event is emitted when a row has been activated by the user. If an item is activatable, double-clicking on the item, using the Return key or calling C<.activate() in Gnome::Gtk4::Widget> will activate the item. Activating instructs the containing view to handle activation. $position is the position of the last clicked selection and @selections is the selection of items used to add items to the list. Any named arguments C<*%options> given to C<.new()> are given to the method.
=begin code
method activate-list-item ( UInt $position, @selections, *%options )
=end code

=item2 Signal factory type events.
=item3 Method setup-list-item; Handles the C<setup> event. The event is emitted to set up permanent things on the B<Gnome::Gtk4::ListItem>. However, the list item is kept under the hood of this class. So, this means the called routine only needs to create and return the widget used in the row. Any named arguments C<*%options> given to C<.new()> are given to the method.
=begin code
method setup-list-item ( *%options --> Gnome::Gtk4::Widget )
=end code

=item3 Method bind-list-item; Handles the C<bind> event. The event is emitted to bind the widgets created by C<.setup-list-item()> to their values and, optionally, add entry specific widgets to the given widget. Signals are connected to listen to changes - both to changes in the item to update the widgets or to changes in the widgets to update the item. After this signal has been called, the listitem may be shown in a list widget. The C<$item> is the string inserted in the list using e.g. C<.append()>. Any named arguments in C<*%options> given to C<.new()> are given to the method.
=begin code
method bind-list-item ( Gnome::Gtk4::Widget $widget, Str $item, *%options )
=end code

=item3 Method unbind-list-item; Handles the C<unbind> event. The event is emitted to undo everything done when binding. Usually this means disconnecting signal handlers or removing non-permanent widgets. Once this signal has been called, the listitem will no longer be used in a list widget.
  The C<bind> and C<unbind> events may be emitted multiple times again to bind the listitem for use with new items. By reusing listitems, potentially costly setup can be avoided. However, it means code needs to make sure to properly clean up the listitem when unbinding so that no information from the previous use leaks into the next one. Any named arguments in C<*%options> given to C<.new()> are given to the method.
=begin code
method unbind-list-item ( Gnome::Gtk4::Widget $widget, Str $item, *%options )
=end code

=item3 Method teardown-list-item; Handles the C<teardown> event. The event is emitted to undo the effects of the C<setup> event. After this signal was emitted on a listitem, the listitem will be destroyed and not be used again. No C<$item> is provided because the item is already destroyed. Any named arguments in C<*%options> given to C<.new()> are given to the method.
=begin code
method teardown-list-item ( Gnome::Gtk4::Widget $widget, *%options )
=end code

=item $!multi-select: Selection method. By default, more than one entry can be selected. Selections can be done a) by holding <CTRL> or <SHIFT> and click on the entries. b) by dragging the pointer over the entries (rubberband select).
=item *%options: Any user options. The options are given to the methods in C<$object>.

=end pod

submethod BUILD ( :$object, Bool :$!multi-select = True, *%options ) {
  $!theme .= new;
  $!theme.add-css-class( self, 'listview-window');

  self.set-halign(GTK_ALIGN_FILL);
  self.set-vexpand(True);
  self.set-propagate-natural-width(True);

  $!list-objects .= new-stringlist(CArray[Str].new(Str));
  $!selection-type = $!multi-select
    ?? Gnome::Gtk4::MultiSelection.new-multiselection($!list-objects)
    !! Gnome::Gtk4::SingleSelection.new-singleselection($!list-objects);
  $!selection-type.register-signal(
    self, 'selection-changed', 'selection-changed', :$object, |%options
  ) if ?$object and $object.^can('selection-changed');

  # See also https://docs.gtk.org/gtk4/class.SignalListItemFactory.html
  with $!signal-factory .= new-signallistitemfactory {
    .register-signal( self, 'setup-list-item', 'setup', :$object, |%options);
    .register-signal( self, 'bind-list-item', 'bind', :$object, |%options);
    .register-signal( self, 'unbind-list-item', 'unbind', :$object, |%options)
      if ?$object and $object.^can('unbind-list-item');
    .register-signal(
      self, 'teardown-list-item', 'teardown', :$object, |%options
    );
  }

  with $!list-view .= new-listview( N-Object, N-Object) {
    .set-model($!selection-type);
    .set-factory($!signal-factory);
    .set-enable-rubberband(True);
    .set-show-separators(True);
    .register-signal(
      self, 'activate-list-item', 'activate', :$object, |%options
    ) if ?$object and $object.^can('activate-list-item');

    $!theme.add-css-class( $!list-view, 'listview-tool');
  }

  self.set-child($!list-view);
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
=begin pod
=head2 get-selection

Get the current selection.

=begin code
method get-selection ( Bool :$rows = False --> List )
=end code

=item $rows: By default a list of items are returned. When row numbers are needed set the variable to True.
=end pod

method get-selection ( Bool :$rows = False --> List ) {

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
