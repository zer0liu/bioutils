#! /usr/bin/perl -w
use strict;

use Glib qw/TRUE FALSE/;
use Gtk2 '-init';
 
#standard window creation, placement, and signal connecting
my $window = Gtk2::Window->new('toplevel');
$window->signal_connect('delete_event' => sub { Gtk2->main_quit; });
$window->set_border_width(5);
$window->set_position('center_always');

#this vbox will geturn the bulk of the gui
my $vbox = &ret_vbox();

#add and show the vbox
$window->add($vbox);
$window->show();

#our main event-loop
Gtk2->main();


sub ret_vbox {

my $hand_cursor = Gtk2::Gdk::Cursor->new ('hand2');
#create a Gtk2::VBox to pack a Gtk2::Frame in. The frame will contain
#a Gtk2::ScrolledWindow, which in turn will contain a Gtk2::VBox full
#of Gtk2::Buttons
my $sw;
my $vbox = Gtk2::VBox->new(FALSE,5);

my $frame = Gtk2::Frame->new();
		#to prove that a Gtk2::Frame can contain somethethig else
		# than a label
		my $check_button = Gtk2::CheckButton->new ("Click Here!");
		
    		$check_button->set_active (TRUE);
		$check_button->signal_connect (toggled => sub {
        		my $self = shift;
			if ($self->get_active){
				# 'activate' the scrolled window and chance the checkbutton's
				# appearance if the user checks the check button.
				my $img_dude = Gtk2::Image->new_from_file("./pix/sweet.jpg");
				#add a touch of detail
				$window->set_icon_from_file ("./pix/dude.jpg"); 
				$sw->set_sensitive (TRUE);
				$check_button->set_label("Sweet, and what about mine?");
				$check_button->set_property('image'=>$img_dude);
				
			}else{
				# 'gray out' the scrolled window and chance the checkbutton's 
				# appearance if the user un-checks the check button.
				my $img_sweet = Gtk2::Image->new_from_file("./pix/dude.jpg");
				#add a touch of detail
				$window->set_icon_from_file ("./pix/sweet.jpg");
        			$sw->set_sensitive (FALSE);
				$check_button->set_label("Dude, what does mine say?");
				$check_button->set_property('image'=>$img_sweet);
			}
    		});
		$check_button->show;
		$check_button->signal_connect('enter' => sub {$check_button->window->set_cursor($hand_cursor);});
		$check_button->signal_connect('leave' => sub {$check_button->window->set_cursor(undef);});
		
	$frame->set_label_widget ($check_button);	
	$frame->set_shadow_type ('out');
	#method of Gtk2::Container
	$frame->set_border_width(10);
	
		$sw = Gtk2::ScrolledWindow->new (undef, undef);
    		$sw->set_shadow_type ('etched-out');
		$sw->set_policy ('never', 'automatic');
		#This is a method of the Gtk2::Widget class,it will force a minimum 
		#size on the widget. Handy to give intitial size to a 
		#Gtk2::ScrolledWindow class object
		$sw->set_size_request (300, 300);
		#method of Gtk2::Container
		$sw->set_border_width(10);
		
			#create a vbox that will contain all the stock buttons
			my $vbox_stock = Gtk2::VBox->new(FALSE,5);
			foreach my $val(sort Gtk2::Stock->list_ids){
				my $btn_stock = Gtk2::Button->new_from_stock($val);
				$vbox_stock->pack_start($btn_stock,FALSE,FALSE,4);
			}
		#add the vbox with all the stock buttons	
		$sw->add_with_viewport($vbox_stock);
	
	$frame->add($sw); 

$vbox->pack_start($frame,TRUE,TRUE,4);
$vbox->show_all();
return $vbox;
}

