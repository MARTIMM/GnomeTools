use v6.d;

#use Getopt::Long;

use GnomeTools::Gtk::Menu;

use Gnome::Gtk4::Application:api<2>;
use Gnome::Gtk4::ApplicationWindow:api<2>;

use Gnome::Gio::ApplicationCommandLine:api<2>;
use Gnome::Gio::T-ioenums:api<2>;

use Gnome::Glib::T-error:api<2>;

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::Application;

has Gnome::Gtk4::Application $!application;
has Gnome::Gtk4::ApplicationWindow $!application-window;

#-------------------------------------------------------------------------------
submethod BUILD ( Str:D $app-id, GApplicationFlags $app-flags ) {
# $!dispatch-testing = True;

  $!application .= new-application(
    APP_ID, G_APPLICATION_HANDLES_COMMAND_LINE
  );
}

#-------------------------------------------------------------------------------
method set-activate ( Any:D $object, Str:D $method ) {
  $!application.register-signal( $object, $method, 'activate');
}

#-------------------------------------------------------------------------------
method set-startup ( Any:D $object, Str:D $method ) {
  $!application.register-signal( $object, $method, 'startup');
}

#-------------------------------------------------------------------------------
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
method local-options (
  N-Object $no-vd, Any:D :$object, Str:D :$method --> Int
) {

  CATCH { default { .message.note; $exit-code = 1; return $exit-code; } }

  my Int $exit-code = $object."$method"();

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
method remote-options (
  Gnome::Gio::ApplicationCommandLine() $cl, Any:D :$object, Str:D :$method
  --> Int
) {

  CATCH { default { .message.note; $exit-code = 1; return $exit-code; } }

  my Array $arguments = $cl.get-arguments()[1..*-1];

  # Returning an exitcode, 0 means ok and continue to activate the primary
  # instance.
  my Int $exit-code = $object."$method"(:$arguments) // 1;

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

