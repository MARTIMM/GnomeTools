
use v6.d;
use NativeCall;

#TODO add css classnames
#TODO also make use of ObjectList to add widgets instead of strings only

use Gnome::Gtk4::DropDown:api<2>;
#use Gnome::Gtk4::StringList:api<2>;
use Gnome::Gtk4::T-types:api<2>;
#use Gnome::Gtk4::SignalListItemFactory:api<2>;
use Gnome::Gtk4::SingleSelection:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;
use Gnome::N::X:api<2>;
#Gnome::N::debug(:on);

use GnomeTools::Gtk::Theming;
use GnomeTools::Gtk::R-ListControl;

#-------------------------------------------------------------------------------
=begin pod
=TITLE GnomeTools::Gtk::DropDown
=head1 Description


=end pod

unit class GnomeTools::Gtk::DropDown:auth<github:MARTIMM>;
also is Gnome::Gtk4::DropDown;
also does GnomeTools::Gtk::R-ListControl;

has GnomeTools::Gtk::Theming $!theme;

#has Gnome::Gtk4::StringList $!list-objects;
#has Gnome::Gtk4::SignalListItemFactory $!signal-factory;
#has Gnome::Gtk4::SingleSelection $!selection-type;

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
submethod BUILD ( :$object, *%options ) {
  $!theme .= new;
  $!theme.add-css-class( self, 'dropdown-tool');

#`{{
  # Initialize the dropdown object with an empty list
  $!list-objects .= new-stringlist(CArray[Str].new(Str));

  $!selection-type =
    Gnome::Gtk4::SingleSelection.new-singleselection($!list-objects);
  $!selection-type.register-signal(
    self, 'selection-changed', 'selection-changed', :$object, |%options
  ) if ?$object and $object.^can('selection-changed');
  $!selection-type.register-signal(
    self, 'selection-changed', 'notify::selected', :$object, |%options
  ) if ?$object and $object.^can('selection-changed');

  with $!signal-factory .= new-signallistitemfactory {
    .register-signal( self, 'setup-list-item', 'setup', :$object, |%options);
    .register-signal( self, 'bind-list-item', 'bind', :$object, |%options);
    .register-signal( self, 'unbind-list-item', 'unbind', :$object, |%options)
      if ?$object and $object.^can('unbind-list-item');
    .register-signal(
      self, 'teardown-list-item', 'teardown', :$object, |%options
    );
  }
}}

  self.init( :!multi-select, :$object, |%options);

  self.set-model($!list-objects);

# No factory! default is ok. also shows mark of selection when list is visible
#  self.set-factory($!signal-factory);
#  self.set-list-factory($!signal-factory);
#  self.set-header-factory($!signal-factory);

  self.set-show-arrow(True);
}

#-------------------------------------------------------------------------------
method set-selection ( @items ) {
#  my Gnome::Gtk4::StringList() $stringlist .= new-stringlist([]);
#  self.set-model($stringlist);
#  my Int $index = 0;
#  my Bool $index-found = False;

  # Add the container strings
  for @items -> $item {
    $!list-objects.append($item);
#    $index-found = True if $item eq $select-item;
#    $index++ unless $index-found;
  }

#  self.set-selected($index-found ?? $index !! 0);
}

#-------------------------------------------------------------------------------
method add-selection ( $item ) {
#  my Gnome::Gtk4::StringList() $stringlist = self.get-model;
#  my Int $index = 0;
#  my Bool $index-found = False;

  # Add the container strings
#  for @items -> $item {
    $!list-objects.append($item);
#    $index-found = True if $item eq $select-item;
#    $index++ unless $index-found;
#  }

#  self.set-selected($index-found ?? $index !! 0);
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

#-------------------------------------------------------------------------------
method trap-dropdown-changes (
  Any:D $helper-object, Str:D $method, *%options
) {
  self.register-signal( $helper-object, $method, 'notify::selected', |%options);
}

