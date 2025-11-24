use v6.d;
use NativeCall;

#use Getopt::Long;

use GnomeTools::Gtk::Menu;

use Gnome::N::N-Object:api<2>;
#use Gnome::N::X:api<2>;
#Gnome::N::debug(:on);

use Gnome::Gtk4::Application:api<2>;
use Gnome::Gtk4::ApplicationWindow:api<2>;
use Gnome::Gtk4::Widget:api<2>;

use Gnome::Gio::ApplicationCommandLine:api<2>;
use Gnome::Gio::T-ioenums:api<2>;

use Gnome::Glib::T-error:api<2>;

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::Application;

has Gnome::Gtk4::Application $!application;
has Gnome::Gtk4::ApplicationWindow $!application-window;

#-------------------------------------------------------------------------------
submethod BUILD (
  Str:D :$app-id, GApplicationFlags :$app-flags = G_APPLICATION_DEFAULT_FLAGS
) {
# $!dispatch-testing = True;
  $!application .= new-application( $app-id, $app-flags);
}

#-------------------------------------------------------------------------------
# Activation of the application takes place when processing remote options
# reach the default entry, or when setup options are processed.
# And when this process is also the primary instance, it's only called once
# because we don't need to create two gui's. This is completely automatically
# done.
method set-activate ( Any:D $object, Str:D $method ) {
  $!application.register-signal( $object, $method, 'activate');
}

#-------------------------------------------------------------------------------
# The startup signal is emitted on the primary instance immediately after
# registration.
method set-startup ( Any:D $object, Str:D $method ) {
  $!application.register-signal( $object, $method, 'startup');
}

#-------------------------------------------------------------------------------
# The shutdown signal is emitted only on the registered primary instance
# immediately after the main loop terminates.
method set-shutdown ( Any:D $object, Str:D $method ) {
  $!application.register-signal( $object, $method, 'shutdown');
}

#-------------------------------------------------------------------------------
method process-local-options ( Any:D $object, Str:D $method ) {
  $!application.register-signal(
    self, 'local-options', 'handle-local-options', :$object, :$method
  );
}

#-------------------------------------------------------------------------------
# private!
method local-options (
  N-Object $no-vd, Any:D :$object, Str:D :$method --> Int
) {
  my Int $exit-code = $object."$method"();

#  CATCH { default { .message.note; $exit-code = 1; return $exit-code; } }

  # Returning an exitcode, 0 means ok but stop local process,
  # -1 means continue to proces remote options and/or activation
  # of primary instance.
  $exit-code // -1
}

#-------------------------------------------------------------------------------
method process-remote-options ( Any:D $object, Str:D $method --> Int ) {
  $!application.register-signal(
    self, 'remote-options', 'command-line', :$object, :$method
  );
}

#-------------------------------------------------------------------------------
# private!
method remote-options (
  Gnome::Gio::ApplicationCommandLine() $cl, Any:D :$object, Str:D :$method
  --> Int
) {

#  CATCH { default { .message.note; $exit-code = 1; return $exit-code; } }

  # Get all arguments from commandline
  my Array $arguments = $cl.get-arguments()[1..*-1];

  # Returning an exitcode, 0 means ok and continue to activate the primary
  # instance.
  my Int $exit-code = $object."$method"(
    $arguments, :remote($cl.get-is-remote)
  ) // 1;

  # finish up
  if $cl.get-is-remote {
    self.setup-window;
  }

  else {
    $!application.activate;
  }

  $cl.done;
  $cl.clear-object;

  $exit-code
}

#-------------------------------------------------------------------------------
method set-window-content (
  Gnome::Gtk4::Widget:D $content, GnomeTools::Gtk::Menu $menu,
  Str :$title = $*PROGRAM-NAME,
) {
  if ?$!application-window and $!application-window.is-valid {
    $!application.remove-window($!application-window);
    $!application-window.destroy;
    $!application-window.clear-object;
  }

  with $!application-window .= new-applicationwindow($!application) {
    if ?$menu {
      $menu.set-actions($!application);
      $!application.set-menubar($menu.get-menu);
      .set-show-menubar(True);
    }

    .set-title($title);
    .set-child($content);
    .present;
  }
note "$?LINE set-window-content";
}

#-------------------------------------------------------------------------------
method run ( ) {
  # Register the application on the dbus
  my $e = CArray[N-Error].new(N-Error);
  $!application.register( N-Object, $e);
  die $e[0].message if ?$e[0];

  # Setup the arguments
  my Int $argc = 1 + @*ARGS.elems;
  my $arg_arr = CArray[Str].new();

  # First argument must be the program name
  $arg_arr[0] = $*PROGRAM.Str;

  # Then, add the list of arguments
  my Int $arg-count = 1;
  for @*ARGS -> $arg {
    $arg_arr[$arg-count++] = $arg;
  }

  # Make a C type array
  my $argv = CArray[Str].new($arg_arr);

  # Start the program with the arguments
  $!application.run( $argc, $argv);
}
