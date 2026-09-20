use v6.d;

use Gnome::Gtk4::StyleContext:api<2>;
use Gnome::Gtk4::CssProvider:api<2>;
use Gnome::Gtk4::N-CssSection:api<2>;
use Gnome::Gtk4::T-csssection:api<2>;
use Gnome::Gtk4::T-csslocation:api<2>;
use Gnome::Gtk4::T-styleprovider:api<2>;
use Gnome::Gtk4::T-enums:api<2>;
use Gnome::Gtk4::Widget:api<2>;
use Gnome::Gtk4::Window:api<2>;
use Gnome::Gtk4::Label:api<2>;

use Gnome::Gdk4::Display:api<2>;
use Gnome::Glib::N-MainLoop:api<2>;

#use Gnome::Glib::N-Error:api<2>;
use Gnome::Glib::T-error:api<2>;

use Gnome::N::N-Object:api<2>;

#-------------------------------------------------------------------------------
=begin pod
=TITLE GnomeTools::Gtk::Dialog
=head1 Description

This module contains a small class aiding in loading css files, and set or unset a class on a widget.

=head2 Example

An example to show how a class is set on a label and how css can be read from a string.

=begin code
my GnomeTools::Gtk::Theming $theme .= new(:css-text(Q:q:to/EOCSS/));
    my-strange-label {
      color: yellow;
      background-color: red;
    }
    EOCSS

my Gnome::Gtk4::Label $label .= new-label;
$label.set-text('yellow characters on a red background');
$theme.add-css-class( $label, 'my-strange-label');
=end code

=end pod

unit class GnomeTools::Gtk::Theming;

my Gnome::Gtk4::CssProvider $css-provider .= new-cssprovider;
my Bool $catch-parser-errors = False;

#-------------------------------------------------------------------------------
=begin pod
=head1 Methods

=head2 new

There are three ways to initialize. The first method doesn't need arguments. This can be used when loading of css files are deferred to a later moment. It can also be used after loading has taken place in another class instance and just need to set or remove a css class on a widget. This is possible because there is only one unique Css provider defined in this class and everything is available there.

  multi submethod BUILD ( )

The other two are

  multi submethod BUILD ( Str:D :$css-path )

end

  multi submethod BUILD ( Str:D :$css-text )

where
=item $css-path; The path to a file with css text.
=item $css-text; A string with css text.

See also the example shown above

=end pod

multi submethod BUILD ( ) {
}

#-------------------------------------------------------------------------------
multi submethod BUILD ( Str:D :$css-path ) {
  self.load-css(:$css-path);
}

#-------------------------------------------------------------------------------
multi submethod BUILD ( Str:D :$css-text ) {
  self.load-css(:$css-text);
}

#-------------------------------------------------------------------------------
=begin pod

=head2 load-css

There are two method to load stylesheets. One to read the sheet from a string and one to read from a file.

  multi method load-css ( Str:D :$css-text )
  
  multi method load-css ( Str:D :$css-path )

=item $css-text; The stylesheet text in a string
=item $css-path; The path to a file which contains the stylesheet
=end pod

multi method load-css ( Str:D :$css-path ) {
  self!process-parse-errors($css-path.IO.basename);
  $css-provider.load-from-path($css-path);
}

#-------------------------------------------------------------------------------
multi method load-css ( Str:D :$css-text ) {
  self!process-parse-errors;
  $css-provider.load-from-string($css-text);
}

#-------------------------------------------------------------------------------
method !process-parse-errors ( Str $file = '' ) {
  if !$catch-parser-errors {
    $css-provider.register-signal(
      self, 'log-css-parsing', 'parsing-error', :$file
    );
    $catch-parser-errors = True;
  }
}

#-------------------------------------------------------------------------------
=begin pod

=head2 add-css-class

Set a css class on a widget.

  method add-css-class ( Gnome::Gtk4::Widget $widget, Str:D $css-class )

=item $widget; The widget to whic the class must be added.
=item $css-class; The name of the class.
=end pod

method add-css-class ( Gnome::Gtk4::Widget $widget, Str:D $css-class ) {

  # It may be defined but has it text?
  return unless ?$css-class;

  my Gnome::Gdk4::Display() $display .= new;
  $display .= get-default;

  my Gnome::Gtk4::StyleContext $style-context .= new;
  $style-context.add-provider-for-display(
    $display, $css-provider, GTK_STYLE_PROVIDER_PRIORITY_USER
  );

  $widget.add-css-class($css-class);
}

#-------------------------------------------------------------------------------
=begin pod

=head2 remove-css-class

Remove a css class from a widget.

  method remove-css-class ( Gnome::Gtk4::Widget $widget, Str:D $css-class )

=item $widget; The widget to whic the class must be added.
=item $css-class; The name of the class.
=end pod

method remove-css-class ( Gnome::Gtk4::Widget $widget, Str:D $css-class ) {

  # It may be defined but has it text?
  return unless ?$css-class;

  my Gnome::Gdk4::Display() $display .= new;
  $display .= get-default;

  my Gnome::Gtk4::StyleContext $style-context .= new;
  $style-context.add-provider-for-display(
    $display, $css-provider, GTK_STYLE_PROVIDER_PRIORITY_USER
  );

  $widget.remove-css-class($css-class);
}

#-------------------------------------------------------------------------------
method log-css-parsing (
  Gnome::Gtk4::N-CssSection() $section, N-Error() $e, Str :$file
) {
  my Gnome::Glib::N-MainLoop $main-loop;
  $main-loop .= new-mainloop( N-Object, True);

  my N-CssLocation() $start-location = $section.get-start-location();
  my N-CssLocation() $end-location = $section.get-end-location();
  my Str $message =
    "CSS error found in style sheet { ?$file ?? $file !! 'text'}\n\n" ~
    "$e.message()\n\n" ~
    "Error found at line {$start-location.lines + 1}\n" ~
    "at character position {$start-location.line-chars + 1}\n" ~
    "{$start-location.chars + 1} characters into the file/text";

  with my Gnome::Gtk4::Label $label .= new-label {
    .set-use-markup(True);
    .set-markup('<span size="large">' ~ $message ~ '</span>');
    .set-halign(GTK_ALIGN_START);
    .set-justify(GTK_JUSTIFY_LEFT);
    .set-wrap(True);
    .set-margin-top(30);
    .set-margin-bottom(30);
    .set-margin-start(30);
    .set-margin-end(30);
  }

  with my Gnome::Gtk4::Window $message-dialog .= new-window {
    .set-child($label);
    .set-destroy-with-parent(True);
    .set-modal(True);
    .set-title('CSS Error');
    .register-signal(
      self, 'destroy-error-dialog', 'close-request',
      :$main-loop, :$message-dialog
    );

    self.add-css-class( $message-dialog, 'error-message');

    .present;

    $main-loop.run;
  }
}

#-------------------------------------------------------------------------------
method destroy-error-dialog (
  Gnome::Glib::N-MainLoop :$main-loop, Gnome::Gtk4::Window :$message-dialog
) {
  note "Program exits after encountering an error";
  $main-loop.quit;
  $message-dialog.destroy;
  $message-dialog.clear-object;
  exit(1);
}


