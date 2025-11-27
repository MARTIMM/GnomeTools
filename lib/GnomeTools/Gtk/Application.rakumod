use v6.d;
use NativeCall;

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
=begin pod
=TITLE GnomeTools::Gtk::Application
=head1 Description

Class to use the B<Gnome::Gtk4::Application> in an easy way. Controlling the behavior of the application is accomplished using the C<:app-flags> when initializing.

=head2 Example

Below is an elaborate example of an application which recognizes 3 options -v
or --verbose, -h or --help, and --version. The flag
G_APPLICATION_HANDLES_COMMAND_LINE means that the program is handling options
from the commandline

=begin code

use v6.d;

use Getopt::Long;

use GnomeTools::Gtk::Application;
use GnomeTools::Gtk::Menu;
# … more imports

# Using globals
my Version $*manager-version = v0.7.1;
my Bool $*verbose = False;
my Str $*config-directory;

my MyApplication $app .= new;
usage if my $ecode = $app.exit-code;
exit($ecode);
sub usage ( ) { … }


unit class MyApplication;
constant APP_ID is export = 'io.mydomain.myapp';

constant LocalOptions = [<version help|h>];
constant RemoteOptions = [ |<verbose|v> ];

has GnomeTools::Gtk::Application $!application;
has Int $.exit-code = 0;

submethod BUILD ( ) {
  with $!application .= new(
    :app-id(APP_ID), :app-flags(G_APPLICATION_HANDLES_COMMAND_LINE)
  ) {
    .set-activate( self, 'app-activate');
    .set-startup( self, 'startup');
    .set-shutdown( self, 'shutdown');
    .process-local-options( self, 'local-options');
    .process-remote-options( self, 'remote-options');

    $!exit-code = .run;
  }
}

method local-options ( --> Int ) {
  # get-options() dies when unknown options are passed
  CATCH { default { .message.note; $!exit-code = 1; return $!exit-code; } }

  # -1: Continue to process remote options and activation of primary instance
  $!exit-code = -1;

  # Local options which do not need a config file or primary instance
  my $o = get-options( |LocalOptions, |RemoteOptions, :!overwrite);
  if $o<version> {
    say "Version of dispatcher is $*manager-version";
    $!exit-code = 0;
  }

  if $o<h>:exists or $o<help>:exists {
    # When set to 1, the main program will always show the help message
    $!exit-code = 1;
  }

  $!exit-code
}

method remote-options ( Array $args, Bool :$is-remote --> Int ) {
  $!exit-code = 0;

  my Capture $o = get-options-from( $args, |RemoteOptions, :overwrite);

  if $o<verbose>:exists {
    $*verbose = True;
  }

  if ?@*ARGS {
    $*config-directory = @*ARGS[0];
    if $*config-directory.IO !~~ :d {
      $!exit-code = 1;
      note "\nConfiguration path '$*config-directory' is not a directory";
    }
  }

  else {
    $!exit-code = 1;
    note "\nYou must specify a sesion directory";
  }

  $!exit-code
}

method startup ( ) {
  # … initialize application
}

method shutdown ( ) {
  # … save configuration unless $!exit-code wasn't 0
}

method app-activate ( ) {
  $!application.set-window-content(
    self.window-content, self.menu, :title("Application Title")
  );
}

method window-content ( --> GnomeTools::Gtk::Widget ) {
  # … Create a widget as content for the application window
}

method menu ( --> GnomeTools::Gtk::Menu ) {
  # … Make a menu for the menu bar at the top
}

=end code

In this example you can see that there are two phases where options are processed. First you need to know that when the program is started, the options are all processed in this first instance. When a second instance is started, the local options are processed in the second instance and the rest of the options are sent to the first. 

=end pod

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::Application;

has Gnome::Gtk4::Application $!application handles <activate>;
has Gnome::Gtk4::ApplicationWindow $!application-window;

#-------------------------------------------------------------------------------
=begin pod
=head1 new

Instantiate the class.



=head2 Arguments

=item Str $app-id. A unique string defined as a reversed domain name as a method to keep application names unique.
=item GApplicationFlags $app-flags. See also L<Gio project T-ioenums|http://127.0.0.1:4000/content-docs/api2/reference/Gio/T-ioenums.html#Gnome::Gio::T-ioenums>.

=end pod
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
method process-remote-options ( Any:D $object, Str:D $method ) {
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
  my Array $args = $cl.get-arguments;
#  my Capture $o = get-options-from( $args[1..*-1], |RemoteOptions);

  # Returning an exitcode, 0 means ok and continue to activate the primary
  # instance.
  my Bool $is-remote = $cl.get-is-remote;
  my Int $exit-code = $object."$method"( $args, :$is-remote) // 1;

  # finish up
  $!application.activate unless $exit-code or $is-remote;
  
  $cl.set-exit-status($exit-code);

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
}

#-------------------------------------------------------------------------------
method run ( ) {
  # Register the application on the dbus
  my $e = CArray[N-Error].new(N-Error);
  $!application.register( N-Object, $e);
  die $e[0].message if ?$e[0];


  # Setup the arguments. This is important because the remote option might
  # come from a 2nd instance.
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
