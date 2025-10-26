
use v6.d;

#TODO also make use of ObjectList to add widgets instead of strings only

#TODO add css classnames
use GnomeTools::Gtk::Theming;

use Gnome::Gtk4::Label:api<2>;
use Gnome::Gtk4::ListBox:api<2>;
use Gnome::Gtk4::ListBoxRow:api<2>;
#use Gnome::Gtk4::StringList:api<2>;
use Gnome::Gtk4::T-types:api<2>;
use Gnome::Gtk4::ScrolledWindow:api<2>;
use Gnome::Gtk4::T-enums:api<2>;
use Gnome::Gtk4::Widget:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;
use Gnome::N::X:api<2>;
#Gnome::N::debug(:on);

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::ListBox:auth<github:MARTIMM>;
also is Gnome::Gtk4::ListBox;

constant ListBox = Gnome::Gtk4::ListBox;
constant ListBoxRow = Gnome::Gtk4::ListBoxRow;
constant Label = Gnome::Gtk4::Label;
constant ScrolledWindow = Gnome::Gtk4::ScrolledWindow;

has GnomeTools::Gtk::Theming $!theme;

#-------------------------------------------------------------------------------
method new ( |c ) {
  self.new-listbox(|c);
}

#-------------------------------------------------------------------------------
submethod BUILD ( Bool :$multi = False, Mu :$object, Str :$method, *%options ) {
  $!theme .= new;
  $!theme.add-css-class( self, 'listbox-tool');

  self.set-selection-mode(GTK_SELECTION_MULTIPLE) if $multi;
#`{{
  self.set-sort-func(
    sub ( N-Object $r1, N-Object $r2, gpointer $ --> int ) {
      my ListBoxRow() $row1 = $r1;
      my ListBoxRow() $row2 = $r2;
      my Label() $l1 = $row1.get-child;
      my Label() $l2 = $row2.get-child;
      my gint $result;
#note "$?LINE ", $r1.(ListBoxRow).get-child.(Label).get-text;

      if $l1.get-text lt $l2.get-text {
        $result = -1;
      }

      elsif $l1.get-text eq $l2.get-text {
        $result = 0;
      }

      else {
        $result = 1;
      }

#note "$?LINE $l1.get-text(), $l2.get-text(), $result";
      $result
    },
    gpointer, gpointer
  );
}}

  if ?$object and ?$method {
    self.register-signal(
      self, 'row-selected', 'row-selected', :$object, :$method, |%options
    );
  }
}

#-------------------------------------------------------------------------------
method row-selected ( ListBoxRow() $row, :$object, :$method, *%options ) {
#note "$?LINE $row.gist(), $object.gist(), $method";
  $object."$method"(
    :row-widget($row.get-child), :$row, :listbox(self), |%options,
  ) if $row.is-valid;
}

#`{{
#-------------------------------------------------------------------------------
method select ( Str:D $select-item ) {
  my Gnome::Gtk4::StringList() $stringlist = self.get-model;
  for ^$stringlist.get-n-items -> $index {
    if $stringlist.get-string($index) eq $select-item {
      self.set-selected($index);
      last;
    }
  }
}
}}

#-------------------------------------------------------------------------------
method set-list (
  Array $list-data, Bool :$mix-widgets = False --> ScrolledWindow
) {
  if $mix-widgets {
    for @$list-data -> $k {
      self.append($k);
    }
  }

  else {
    for @$list-data.sort({$^a.lc cmp $^b.lc}) -> $k {
      with my Label $l .= new-label {
        .set-hexpand(True);
        .set-text($k);
        .set-justify(GTK_JUSTIFY_LEFT);
        .set-halign(GTK_ALIGN_START);
      }

      self.append($l);
    }
  }

  with my ScrolledWindow $sw .= new-scrolledwindow {
    .set-child(self);
    .set-size-request( 850, 300);
  }

  $sw
}

#-------------------------------------------------------------------------------
method reset-list ( Array $list-data ) {
  with self {
    .unselect-all;
    .remove-all;
    for $list-data.sort({$^a.lc cmp $^b.lc}) -> $k {
      if $k ~~ Str {
        with my Label $l .= new-label {
          .set-hexpand(True);
          .set-text($k);
          .set-justify(GTK_JUSTIFY_LEFT);
          .set-halign(GTK_ALIGN_START);
        }

        .append($l);
      }

      else {
        .append($k);
      }
    }
  }
}

#-------------------------------------------------------------------------------
multi method append-list ( Str $entry-text ) {
  with my Label $l .= new-label {
    .set-text($entry-text);
    .set-justify(GTK_JUSTIFY_LEFT);
    .set-halign(GTK_ALIGN_START);
  }

  with self {
    .append($l);
    .select-row($l);
  }
}

#-------------------------------------------------------------------------------
multi method append-list ( Gnome::Gtk4::Widget $widget ) {
  with $widget {
    .set-justify(GTK_JUSTIFY_LEFT);
    .set-halign(GTK_ALIGN_START);
  }

  with self {
    .append($widget);
    .select-row($widget);
  }
}

#-------------------------------------------------------------------------------
method get-selection ( Bool :$get-widgets = False --> Array ) {
  my Array $select = [];
  self.selected-foreach(
    -> N-Object $nlb, N-Object $nlbr, gpointer $ {
      my ListBox() $box = $nlb;
      my ListBoxRow() $row = $nlbr;
      if $get-widgets {
        $select.push: $row.get-child;
      }

      else {
        my Label() $l = $row.get-child;
        $select.push: $l.get-text;
      }
    },
    gpointer
  );

  $select
}

#-------------------------------------------------------------------------------
# Set selections in the listbox using the given selections array.
# Only for strings in array and Label in ListBox.
method set-selection ( Array $selections --> Array ) {
  for ^1000 -> $index {

    # Get the listbox row. if undefined, w're done
    my N-Object $no = self.get-row-at-index($index);
    last unless ?$no;

    # Get the row object and reset selection
    my ListBoxRow() $lbr = $no;
    self.unselect-row($lbr);

    # Get the label text
    my Label() $label = $lbr.get-child;
    my Str $text = $label.get-text;

    # Work through the selections and test the row text against the selection
    for @$selections -> $selection {
      if $selection eq $text {
        self.select-row($lbr);
        last;
      }
    }
  }
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

#  my Str $select-container = self.get-text;
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
    '', self.get-text, $!config.get-current-root, :$skip-default
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

#  my Str $select-root = self.get-text;
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
#note "$?LINE $roots.get-text(), ", self.get-text;
#note "$?LINE ", ?$categories ?? $containers.get-text !! '-';
  my $root-dir = self.get-text;
  $containers.fill-containers( '', $root-dir, :$skip-default);

  # no need to check because drop down is filled with existing data
  $!config.set-table-root($root-dir);
#note "$?LINE ", (?$categories ?? $containers.get-text !! '-'), ', ', $root-dir;

  $categories.fill-categories(
    '', $containers.get-text, $root-dir, :$skip-default
  ) if ?$categories;
}

