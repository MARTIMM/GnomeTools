use v6;

use NativeCall;

=begin pod
=TITLE GnomeTools::Gtk::DND
=head1 Description

The DND class is designed to simplify the Drag and Drop bussines.

=end pod

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::DND;

use Gnome::Gtk4::EventController:api<2>;
use Gnome::Gtk4::DropTarget:api<2>;
use Gnome::Gtk4::DropTargetAsync:api<2>;
use Gnome::Gtk4::DragSource:api<2>;
use Gnome::Gtk4::Picture:api<2>;
use Gnome::Gtk4::Widget:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::N-Object:api<2>;
use Gnome::N::X:api<2>;
#Gnome::N::debug(:on);

use Gnome::Gdk4::Drag:api<2>;
use Gnome::Gdk4::Drop:api<2>;
use Gnome::Gdk4::ContentProvider:api<2>;
use Gnome::Gdk4::N-ContentFormats:api<2>;
use Gnome::Gdk4::T-enums:api<2>;

use Gnome::Glib::N-Error:api<2>;
use Gnome::Glib::T-error:api<2>;

use Gnome::GObject::T-type:api<2>;
use Gnome::GObject::N-Value:api<2>;
use Gnome::GObject::T-value:api<2>;

use Gnome::Gio::Task:api<2>;

#-------------------------------------------------------------------------------
has Array $!target-area;

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods

=end pod

#submethod BUILD ( ) { }

#-------------------------------------------------------------------------------
=begin pod
=head2 set-dragsource

Set up a source widget from where to drag from.

=begin code
method set-dragsource (
  $object, Gnome::Gtk4::Widget $widget, Str $drag-content, *%options
)
=end code

=item $object; The object where callback methods are to be found when defined. The possible methods are;
=item2 drag-prepare; Prepare a drag operation. It is meant to return a B<Gnome::Gdk4::ContentProvider> with a content to send at a later time. The callback api must be C<:( Rat() $x, Rat() $y, *%options --> N-Object )>. For all callbacks %options are the options given to C<.set-dragsource()>.
=item2 drag-begin;
=item2 drag-end;
=item2 drag-cancel;
=item $widget;
=item $drag-content;
=item %options;

=end pod

method set-dragsource (
  $object, Gnome::Gtk4::Widget $widget, Str $drag-content, *%options
) {
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

    #.set-icon( $pic.get-paintable, -20, 20);
  }

  # Set content. Can use multiple strings. Interface has variable list solved
  # by providing pairs of type/value. In this case gchar-ptr/$drag-content
  my Gnome::Gdk4::ContentProvider $cp .= new-typed(
    G_TYPE_STRING, gchar-ptr, $drag-content // ''
  );
  $source.set-content($cp);

  $widget.add-controller($source);
  $source.clear-object;
}

#-------------------------------------------------------------------------------
method set-droptarget (
  $object, Gnome::Gtk4::Widget $target-widget, Bool :$async = False, *%options
) {

  my Gnome::Gtk4::EventController $target;
  if $async {
  # The data may be of the content type
    my Gnome::Gdk4::N-ContentFormats $formats .= new-contentformats(
      CArray[Str].new(<text/uri-list text/plain>), 1
    );

    $target = Gnome::Gtk4::DropTargetAsync.new-droptargetasync(
      $formats, GDK_ACTION_COPY +| GDK_ACTION_MOVE +| GDK_ACTION_LINK
    );
  }

  else {
    $target = Gnome::Gtk4::DropTarget.new-droptarget(
      G_TYPE_STRING, GDK_ACTION_COPY +| GDK_ACTION_MOVE +| GDK_ACTION_LINK
    );
  }

  with $target {
#    .set-gtypes( CArray[GType].new($n-fl.get-class-gtype), 1);

    my Gnome::Gdk4::N-ContentFormats() $formats = .get-formats;
    my $size = CArray[gsize].new(0);
    my Array $mime-types = $formats.get-mime-types($size);

    loop ( my Int $i = 0; $i < $size[0]; $i++ ) {
      note "Mime type: ", $mime-types[$i];
    }

    .register-signal( $object, 'drop-accept', 'accept', |%options)
      if $object.^can('drop-accept');

    if $async {
      .register-signal( $object, 'drop-async', 'drop', |%options)
        if $object.^can('drop-async');
      .register-signal( $object, 'drop-enter-async', 'drag-enter', |%options)
        if $object.^can('drop-enter-async');
      .register-signal( $object, 'drop-leave-async', 'drag-leave', |%options)
        if $object.^can('drop-leave-async');
      .register-signal( $object, 'drop-motion-async', 'drag-motion', |%options)
        if $object.^can('drop-motion-async');
    }

    else {
      .register-signal( $object, 'drop', 'drop', |%options)
        if $object.^can('drop');
      .register-signal( $object, 'drop-enter', 'enter', |%options)
        if $object.^can('drop-enter');
      .register-signal( $object, 'drop-leave', 'leave', |%options)
        if $object.^can('drop-leave');
      .register-signal( $object, 'drop-motion', 'motion', |%options)
        if $object.^can('drop-motion');
    }

    $target-widget.add-controller($target);
    .clear-object;
  }
}

#-------------------------------------------------------------------------------
method check-accept ( Gnome::Gdk4::Drop() $drop, Str $test-mime --> Bool ) {
  my Array $mime-types = self.get-mimetypes($drop);
#  self.show-mimetypes($mime-types);
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
  N-Value $n-value, Gnome::Gtk4::DropTarget $drop-target
  --> List
) {
  my Gnome::GObject::N-Value $value .= new(:native-object($n-value));

  my Gnome::Gdk4::Drop() $drop = $drop-target.get-current-drop;
  my Gnome::Gdk4::Drag() $drag = $drop.get-drag;
  my Bool $internal = $drag.is-valid;

  ( $internal, $value.get-string )
}

#-------------------------------------------------------------------------------
method get-dropped-value-async (
  $object, Str $method, Gnome::Gdk4::Drop $drop,
  UInt $priority, Rat $x, Rat $y
) {
  die "Not useful if method '$method' is not defined"
    unless $object.^can($method); 
  $drop.read-value-async(
    G_TYPE_STRING, $priority, gpointer,
    sub ( Gnome::Gdk4::Drop() $drop, Gnome::Gio::Task() $result, gpointer $ ) {
      my $e = CArray[N-Error].new(N-Error);
      my N-Value $nv = nativecast(
        N-Value, $drop.read-value-finish( $result, $e)
      );
      if $e[0].defined {
        note "Dnd error: ", $e[0].message;
      }

      else {
        my Gnome::GObject::N-Value $v .= new(:native-object($nv));
#        note "Dropped values:";
#        note '  ', $v.get-string.split("\n").join("\n  ");
        my Gnome::Gdk4::Drag() $drag = $drop.get-drag;
        my Bool $internal = $drag.is-valid;
        $object."$method"( $internal, $v.get-string);
      }

      $drop.finish(GDK_ACTION_COPY);

    }, gpointer
  );
}
