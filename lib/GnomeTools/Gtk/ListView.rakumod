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
also does GnomeTools::Gtk::R-ListModel;

has GnomeTools::Gtk::Theming $!theme;
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
submethod BUILD ( Bool :$!multi-select = True )
=end code

=item $!multi-select: Selection method. When True, more than one entry can be selected. By default False. Selections can be done a) by holding <CTRL> or <SHIFT> and click on the entries. b) by dragging the pointer over the entries (rubberband select).
=end pod

submethod BUILD ( Bool :$multi-select = False ) {
  $!theme .= new;
  $!theme.add-css-class( self, 'listview-window');

  self.set-halign(GTK_ALIGN_FILL);
  self.set-vexpand(True);
  self.set-propagate-natural-width(True);

  self!init(:$multi-select);

  with $!list-view .= new-listview( N-Object, N-Object) {
    .set-model($!selection-type);
    .set-factory($!signal-factory);
    .set-enable-rubberband(True);
    .set-show-separators(True);

    $!theme.add-css-class( $!list-view, 'listview-tool');
  }

  self.set-child($!list-view);
}

#-------------------------------------------------------------------------------
=begin pod
=head2 set-events

Register a series of events based on the B<Gnome::Gtk4::SignalListItemFactory> class.

=item2 Events from ListView.
=item3 Method activate-list-item; The C<activate> event is emitted when a row has been activated by the user. If an item is activatable, double-clicking on the item, using the Return key or calling C<.activate() in Gnome::Gtk4::Widget> will activate the item. Activating instructs the containing view to handle activation. $position is the position of the last clicked selection and @selections is the selection of items used to add items to the list. Any named arguments C<*%options> given to C<.new()> are given to the method.
=begin code
method activate-list-item ( UInt $position, @selections, *%options )
=end code

=begin code
method set-events ( :$object, *%options )
=end code
=item $object; User object where methods are defined to process the events. There are many events which can be processed so the method names are fixed for simplicity. The method names are C<selection-changed> for the selection-changed event, C<activate-list-item> for the activate event, C<setup-list-item> to handle the setup event, C<bind-list-item> handles the bind event, C<unbind-list-item> handles the unbind event, and C<teardown-list-item> for the teardown event. The methods are not called when they are not defined.
=item *%options: Any user options. The options are given to the methods in C<$object>.
=end pod
method set-events ( :$object, *%options ) {

  $!list-view.register-signal(
    self, 'activate-list-item', 'activate', :$object, |%options
  ) if ?$object and $object.^can('activate-list-item');

  self!set-events( :$object, |%options);


#note "$?LINE ", self.^can("set-events");
#note "$?LINE ", self.methods;
}

#-------------------------------------------------------------------------------
method activate-list-item ( UInt $position, :$object, *%options ) {
  $object.activate-list-item( $position, self.get-selection, |%options);
}
