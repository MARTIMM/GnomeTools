use v6.d;
use NativeCall;

#use GnomeTools::Gtk::Application;

use Gnome::Gtk4::ShortcutController:api<2>;
use Gnome::Gtk4::Shortcut:api<2>;
use Gnome::Gtk4::ShortcutTrigger:api<2>;
use Gnome::Gtk4::CallbackAction:api<2>;
use Gnome::Gtk4::T-enums:api<2>;
use Gnome::Gtk4::Widget:api<2>;

use Gnome::N::N-Object:api<2>;
use Gnome::N::GlibToRakuTypes:api<2>;

use Gnome::Gio::SimpleAction:api<2>;

use Gnome::Glib::N-MainLoop:api<2>;

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::Shortcut;

#-------------------------------------------------------------------------------
#submethod BUILD ( ) { }

#-------------------------------------------------------------------------------
multi method set-shortcut (
  Str $shortcut-string, Gnome::Gtk4::Widget $widget, $object, $method, *%options
) {
  my Gnome::Gtk4::ShortcutTrigger $st .= parse-string($shortcut-string);
  my Gnome::Gtk4::CallbackAction $ca .= new-callbackaction(
    sub ( N-Object $no, N-Object $, gpointer $ ) {
      $object."$method"(|%options);
    },
    gpointer, gpointer
  );

  my Gnome::Gtk4::Shortcut $sc .= new-shortcut( $st, $ca);

  with my Gnome::Gtk4::ShortcutController $scc .= new-shortcutcontroller() {
    .set-scope(GTK_SHORTCUT_SCOPE_GLOBAL);
    .add-shortcut($sc);
  }

  $widget.add-controller($scc);
}

#-------------------------------------------------------------------------------
multi method set-shortcut (
  Gnome::Gtk4::Widget $application, Str $shortcut-string,
  $object, $method, *%options
) {
  my Gnome::Gio::SimpleAction $action;
  $action .= new-simpleaction( $method, gpointer);
  $action.register-signal( $object, $method, 'activate', |%options);
  $application.add-action($action);
  $application.set-accels-for-action(
    "app.$method", CArray[Str].new($shortcut-string)
  );
}


=finish

https://docs.gtk.org/gtk4/func.accelerator_parse.html

The format looks like “<Control>a” or “<Shift><Alt>F1”.

The parser is fairly liberal and allows lower or upper case, and also abbreviations such as “<Ctl>” and “<Ctrl>”.

Key names are parsed using gdk_keyval_from_name(). For character keys the name is not the symbol, but the lowercase name, e.g. one would use “<Ctrl>minus” instead of “<Ctrl>-”.

Modifiers are enclosed in angular brackets <>, and match the GdkModifierType mask:
<Shift> for GDK_SHIFT_MASK
<Ctrl> for GDK_CONTROL_MASK
<Alt> for GDK_ALT_MASK
<Meta> for GDK_META_MASK
<Super> for GDK_SUPER_MASK
<Hyper> for GDK_HYPER_MASK

