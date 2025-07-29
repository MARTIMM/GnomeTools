use v6.d;

#TODO add icons for type of message: info, warning, error, fatal, debug

use GnomeTools::Gtk::Dialog;

use Gnome::Gtk4::Label:api<2>;

#-------------------------------------------------------------------------------
unit class GnomeTools::Gtk::MessageDialog:auth<github:MARTIMM>;
also is GnomeTools::Gtk::Dialog;

#-------------------------------------------------------------------------------
submethod BUILD ( Str :$message ) {
  self.add-content( $message, Gnome::Gtk4::Label.new-label);
  self.set-title('Message Dialog');

  self.add-button( self, 'destroy-dialog', 'Ok');
  self.show-dialog;
}

