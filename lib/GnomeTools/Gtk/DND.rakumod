use v6;

use NativeCall;


#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::DND;

use Gnome::Gtk4::DropTarget:api<2>;
use Gnome::Gtk4::DragSource:api<2>;
use Gnome::Gtk4::Picture:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;
use Gnome::N::X:api<2>;
#Gnome::N::debug(:on);

use Gnome::Gdk4::ContentProvider:api<2>;
use Gnome::Gdk4::Drag:api<2>;
use Gnome::Gdk4::Drop:api<2>;
use Gnome::Gdk4::ContentProvider:api<2>;
use Gnome::Gdk4::N-ContentFormats:api<2>;
use Gnome::Gdk4::T-enums:api<2>;

use Gnome::Glib::N-Error:api<2>;
use Gnome::Glib::T-error:api<2>;

use Gnome::GObject::T-type:api<2>;

use Gnome::GObject::T-type:api<2>;
use Gnome::GObject::N-Value:api<2>;
use Gnome::GObject::T-value:api<2>;

#-------------------------------------------------------------------------------
has Array $!target-area;

#-------------------------------------------------------------------------------
#submethod BUILD ( ) { }


#-------------------------------------------------------------------------------
method set-dragsource (
  $object, Str $pic-file, Str $drag-content, *%options
  --> Gnome::Gtk4::Picture
) {
  my Gnome::Gtk4::Picture $pic;
  $pic .= new-for-filename($pic-file);
  $pic.set-size-request( 100, 100);
  with my Gnome::Gtk4::DragSource $source .= new-dragsource {
    # Possible to set content provider in 'prepare()' or below.
    .register-signal(
      $object, 'drag-prepare', 'prepare', |%options
    ) if $object.^can('drag-prepare');
    .register-signal( $object, 'drag-begin', 'drag-begin', |%options)
      if $object.^can('drag-begin');
    .register-signal( $object, 'drag-end', 'drag-end', |%options)
      if $object.^can('drag-end');
    .register-signal( $object, 'drag-cancel', 'drag-cancel', |%options)
      if $object.^can('drag-cancel');

    .set-icon( $pic.get-paintable, -20, 20);
  }

  # Set content. Can use multiple strings. Interface has variable list solved
  # by providing pairs of type/value. Inthis case gchar-ptr/$pic-file
  my Gnome::Gdk4::ContentProvider $cp .= new-typed(
    G_TYPE_STRING, gchar-ptr, $drag-content
  );
  $source.set-content($cp);

  $pic.add-controller($source);
  $source.clear-object;

  $pic
}

#-------------------------------------------------------------------------------
method set-droptarget ( $object, Gnome::Gtk4::Picture $target-pic, *%options ) {

  my Gnome::Gtk4::DropTarget $target;
  with $target .= new-droptarget( G_TYPE_STRING, GDK_ACTION_COPY) {
#    .set-gtypes( CArray[GType].new($n-fl.get-class-gtype), 1);

    my Gnome::Gdk4::N-ContentFormats() $formats = .get-formats;
    my $size = CArray[gsize].new(0);
    my Array $mime-types = $formats.get-mime-types($size);

    loop ( my Int $i = 0; $i < $size[0]; $i++ ) {
      note "Mime type: ", $mime-types[$i];
    }

    .register-signal( $object, 'drag-accept', 'accept', |%options)
      if $object.^can('drag-accept');
    .register-signal( $object, 'drag-drop', 'drop', |%options)
      if $object.^can('drag-drop');
    .register-signal( $object, 'drag-enter', 'enter', |%options)
      if $object.^can('drag-enter');
    .register-signal( $object, 'drag-leave', 'leave', |%options)
      if $object.^can('drag-leave');
    .register-signal( $object, 'drag-motion', 'motion', |%options)
      if $object.^can('drag-motion');

    $target-pic.add-controller($target);
    .clear-object;
  }
}

#-------------------------------------------------------------------------------
method check-accept ( Gnome::Gdk4::Drop() $drop, Str $test-mime --> Bool ) {
  my Array $mime-types = self.get-mimetypes($drop);
  self.show-mimetypes($mime-types);

  self.check-mimetype( $test-mime, $mime-types)
}

#-------------------------------------------------------------------------------
method get-mimetypes ( Gnome::Gdk4::Drop $drop --> Array ) {
  my Gnome::Gdk4::N-ContentFormats() $formats = $drop.get-formats;
  my $size = CArray[gsize].new(0);
  my Array $mime-types = $formats.get-mime-types($size);

  $mime-types
}

#-------------------------------------------------------------------------------
method show-mimetypes ( Array $mime-types ) {
  for @$mime-types -> $mime-type {
    note "show-mimetypes: Mime type: $mime-type";
  }
}

#-------------------------------------------------------------------------------
method show-actions ( GFlag $actions ) {
  for GDK_ACTION_COPY, GDK_ACTION_MOVE, GDK_ACTION_LINK -> $action {
    note "Action $action found" if $actions &? $action;
  }
}

#-------------------------------------------------------------------------------
method check-mimetype ( Str $lookfor, Array $mime-types --> Bool ) {
  my Bool $ok = False;
  for @$mime-types -> $mime-type {
    if $mime-types ~~ m/ $lookfor / {
      $ok = True;
      last;
    }
  }

  $ok
}

#-------------------------------------------------------------------------------
method get-dropped-value (
  N-Value() $n-value, Gnome::Gtk4::DropTarget() $drop-target
  --> List
) {
  my Gnome::GObject::N-Value $value .= new(:native-object($n-value));

  my Gnome::Gdk4::Drop() $drop = $drop-target.get-current-drop;
  my Gnome::Gdk4::Drag() $drag = $drop.get-drag;
  my Bool $internal = $drag.is-valid;

  ( $internal, $value.get-string )
}
