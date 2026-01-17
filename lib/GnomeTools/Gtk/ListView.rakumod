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

my GnomeTools::Gtk::ListView $listview .= new(:!multi-select);
$listview.set-events( :object($helper), :$dialog);
$listview.append(|@items);
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

Instantiate the C<GnomeTools::Gtk::ListView> class.

=begin code
submethod BUILD ( Bool :$!multi-select = False )
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

Register a series of events. One defined in B<Gnome::Gtk4::ListView> and the rest from B<Gnome::Gtk4::SignalListItemFactory> class.

=begin code
method set-events ( :$object, *%options )
=end code
=item $object; User object where methods are defined to process the events. There are many events, so the method names are fixed for simplicity. Most events are defined by B<Gnome::Gtk4::SignalListItemFactory>. The info can be looked up L<here|/content-docs/api2/reference/Gtk4/SignalListItemFactory> or L<here|/content-docs/GnomeTools/reference/Gtk/R-ListModel>.
  The method is not called when it isn't defined.
=item *%options: Any user options. The options is given to the method in C<$object>.

The event defined in B<nome::Gtk4::ListView> is C<activate> and the method called will be C<activate-list-item>. The C<activate> event is emitted when a row has been activated by the user. If an item is activatable, double-clicking on the item, using the Return key or calling C<.activate() in Gnome::Gtk4::Widget> will activate the item. Activating instructs the containing view to handle activation.

The user callback interface must be like;
=begin code
method activate-list-item ( UInt $position, @selections, *%options )
=end code

Where;
=item $position; Position is the last clicked selection.
=item @selections; The list of selections in the ListView. Any named arguments C<*%options> given to C<.new()> are given to the method.
=end pod

method set-events ( :$object, *%options ) {
  $!list-view.register-signal(
    self, 'activate-list-item', 'activate', :$object, |%options
  ) if ?$object and $object.^can('activate-list-item');

  self!set-events( :$object, |%options);
}

#-------------------------------------------------------------------------------
method activate-list-item ( UInt $position, :$object, *%options ) {
  $object.activate-list-item( $position, self.get-selection, |%options);
}
