
use v6.d;

use Gnome::Gtk4::DropDown:api<2>;
use Gnome::Gtk4::StringList:api<2>;
use Gnome::Gtk4::T-types:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;
use Gnome::N::X:api<2>;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::DropDown:auth<github:MARTIMM>;
also is Gnome::Gtk4::DropDown;

#-------------------------------------------------------------------------------
multi method new ( N-Object $model, N-Object $expression, |c ) {
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
  my Gnome::Gtk4::StringList $stringlist .= new-stringlist([]);
  self.set-model($stringlist);
}

#-------------------------------------------------------------------------------
method set-selection ( @items, Str :$select-item = '' ) {
  my Gnome::Gtk4::StringList() $stringlist .= new-stringlist([]);
  self.set-model($stringlist);
  my Int $index = 0;
  my Bool $index-found = False;

  # Add the container strings
  for @items -> $item {
#note "$?LINE   item: $item";

    $stringlist.append($item);
    $index-found = True if $item eq $select-item;
    $index++ unless $index-found;
  }

  self.set-selected($index-found ?? $index !! 0);
}

#-------------------------------------------------------------------------------
method get-dropdown-text ( --> Str ) {
#say Backtrace.new.nice;
  my Gnome::Gtk4::StringList() $stringlist;
  my UInt $p;
  $stringlist = self.get-model;
  $p = self.get-selected;

  my Str $s = '';
  $s = $stringlist.get-string($p) unless $p == GTK_INVALID_LIST_POSITION;

  $s
}









=finish
#-------------------------------------------------------------------------------
method fill-containers (
  Str:D $select-container, Str $root-dir, Bool :$skip-default = False
) {
#note "$?LINE {$select-container//'-'}, $root-dir";

  $root-dir //= $!config.get-current-root;
  self.set-selection(
    $!config.get-containers($root-dir), $select-container, :$skip-default
  );
}

#-------------------------------------------------------------------------------
method fill-roots ( Str:D $select-root ) {
#note "$?LINE $select-root";

  self.set-selection( $!config.get-roots, $select-root);
}

#-------------------------------------------------------------------------------
# Only a container drop down list can call this
method trap-container-changes (
  PuzzleTable::Gui::DropDown $categories, Bool :$skip-default = False
) {
  self.register-signal(
    self, 'select-categories', 'notify::selected',
    :$categories, :$skip-default
  );

#  my Str $select-container = self.get-dropdown-text;
}

#-------------------------------------------------------------------------------
=begin pod
=head2 select-categories

Handler for the container dropdown list to change the category dropdown list after a selecteion is made.

  method select-categories (
    N-Object $, Gnome::Gtk4::DropDown() :_native-object($containers),
    Gnome::Gtk4::DropDown() :$categories, Bool :$skip-default
  )

=item $ ; A ParamSpec object. It is ignored.
=item $containers: The container list.
=item $categories: The category list.
=item $skip-default; Used to hide the 'Default' category from the list.

=end pod

#TODO somehow there is an empty stringlist when using _native-object named argument
method select-categories (
  N-Object $, # PuzzleTable::Gui::DropDown() :_native-object($containers),
  PuzzleTable::Gui::DropDown :$categories, Bool :$skip-default,
) {
  $categories.fill-categories(
    '', self.get-dropdown-text, $!config.get-current-root, :$skip-default
  );
}

#-------------------------------------------------------------------------------
# Only a container drop down list can call this
method trap-root-changes (
  PuzzleTable::Gui::DropDown $containers,
  PuzzleTable::Gui::DropDown :$categories,
  Bool :$skip-default = False
) {
#  state $roots = self;
  self.register-signal(
    self, 'select-containers', 'notify::selected',
    :$containers, :$categories, :$skip-default
  );

#  my Str $select-root = self.get-dropdown-text;
}

#-------------------------------------------------------------------------------
=begin pod

=end pod

#TODO somehow there is an empty stringlist when using _native-object named argument
method select-containers (
  N-Object $, # PuzzleTable::Gui::DropDown() :_native-object($containers),
#  PuzzleTable::Gui::DropDown :$roots,
  PuzzleTable::Gui::DropDown :$containers,
  PuzzleTable::Gui::DropDown :$categories,
  Bool :$skip-default,
) {
#note "$?LINE $roots.get-dropdown-text(), ", self.get-dropdown-text;
#note "$?LINE ", ?$categories ?? $containers.get-dropdown-text !! '-';
  my $root-dir = self.get-dropdown-text;
  $containers.fill-containers( '', $root-dir, :$skip-default);

  # no need to check because drop down is filled with existing data
  $!config.set-table-root($root-dir);
#note "$?LINE ", (?$categories ?? $containers.get-dropdown-text !! '-'), ', ', $root-dir;

  $categories.fill-categories(
    '', $containers.get-dropdown-text, $root-dir, :$skip-default
  ) if ?$categories;
}

