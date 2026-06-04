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

use Gnome::Gdk4::ContentProvider;
use Gnome::Gdk4::Drag:api<2>;
use Gnome::Gdk4::T-drag:api<2>;
use Gnome::Gdk4::T-enums:api<2>;

use Gnome::Glib::N-Error:api<2>;
use Gnome::Glib::T-error:api<2>;

use Gnome::GObject::T-type:api<2>;

#-------------------------------------------------------------------------------
#submethod BUILD ( ) { }

#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
method set-dragsource (
  $object, Str $pic-file, *%options
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
    G_TYPE_STRING, gchar-ptr, $pic-file
  );
  $source.set-content($cp);

  $pic.add-controller($source);
  $source.clear-object;

  $pic
}

#-------------------------------------------------------------------------------
method set-droptarget (
  $object, Str $pic-file, *%options
  --> Gnome::Gtk4::Picture
) {

  my Gnome::Gtk4::Picture $pic;
  my Gnome::Gtk4::DropTarget $target;
  with $target .= new-droptarget( G_TYPE_STRING, GDK_ACTION_COPY) {
#    .set-gtypes( CArray[GType].new($n-fl.get-class-gtype), 1);
note "$?LINE Preload: ", .get-preload;

    my Gnome::Gdk4::N-ContentFormats() $formats = .get-formats;
    my $size = CArray[gsize].new(0);
    my Array $mime-types = $formats.get-mime-types($size);

note "$?LINE $size.gist(), $mime-types.elems()";
    loop ( my Int $i = 0; $i < $size[0]; $i++ ) {
      note "Mime type: ", $mime-types[$i];
    }

#    .register-signal( $object, 'drag-accept', 'accept', |%options)
#      if $object.^can('drag-accept');
    .register-signal( $object, 'drag-drop', 'drop', |%options)
      if $object.^can('drag-drop');
    .register-signal( $object, 'drag-enter', 'enter', |%options)
      if $object.^can('drag-enter');
    .register-signal( $object, 'drag-leave', 'leave', |%options)
      if $object.^can('drag-leave');
    .register-signal( $object, 'drag-motion', 'motion', |%options)
      if $object.^can('drag-motion');

    $pic .= new-for-filename($pic-file);
    $pic.add-controller($target);
    .clear-object;
  }

  $pic
}
