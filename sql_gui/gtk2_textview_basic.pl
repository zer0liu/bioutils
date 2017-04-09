#! /usr/bin/perl -w
use strict;

use Gtk2 '-init';
use Glib qw/TRUE FALSE/;
use Gtk2::Pango; 

#anchor for a checkbutton
my $check_anchor;
#anchor for a normal button
my $submit_anchor;

my $hovering_over_link = FALSE;
#the two cursors that we want to use
my $pencil_cursor = Gtk2::Gdk::Cursor->new ('pencil');
my $point_cursor = Gtk2::Gdk::Cursor->new ('shuttle');
 
#standard window creation, placement, and signal connecting
my $window = Gtk2::Window->new('toplevel');
$window->signal_connect('delete_event' => sub { Gtk2->main_quit; });
$window->set_border_width(5);
#$window->set_position('center_always');

	$window->set_property ('window-position' => 'center_always');

#this vbox will geturn the bulk of the gui
my $vbox = &ret_vbox();

#add and show the vbox
$window->add($vbox);
$window->show();
	
#our main event-loop
Gtk2->main();

sub ret_vbox {

my $vbox = Gtk2::VBox->new(FALSE,5);

	my $frame = Gtk2::Frame->new("Gtk2::TextView - Gentle Introduction");
		
	#method of Gtk2::Container
	$frame->set_border_width(5);
		#create a scrolled window to put the textview in
		my $sw = Gtk2::ScrolledWindow->new (undef, undef);
    		$sw->set_shadow_type ('etched-out');
		$sw->set_policy ('automatic', 'automatic');
		#This is a method of the Gtk2::Widget class,it will force a minimum 
		#size on the widget. Handy to give intitial size to a 
		#Gtk2::ScrolledWindow class object
		$sw->set_size_request (500, 200);
		#method of Gtk2::Container
		$sw->set_border_width(5);
			
			#we create and build the buffer
			my $buffer = &create_buffer;
			#we add this buffer to a new textview
			my $tview = Gtk2::TextView->new_with_buffer($buffer);
			#if we want to change the cursors, we have to connect the
			#motion_notify_event to a sub that will handle it
			$tview->signal_connect (motion_notify_event => \&motion_notify_event);
				#create a widget to add to the textview's anchor		
				my $chk_button = Gtk2::CheckButton->new();
			#attach this widget to the textview's anchor
			$tview->add_child_at_anchor ($chk_button, $check_anchor);
				#create a widget to add to the textview's anchor
				my $btn_submit = Gtk2::Button->new("_Submit");
			#attach this widget to the textview's anchor
			$tview->add_child_at_anchor ($btn_submit, $submit_anchor);
			#we do not want to edit anything else than specified text.
			$tview->set_editable(FALSE);			
		#add the textview to the scrolled window		
  		$sw->add($tview);
	#add the scrolledwindow to the frame
	$frame->add($sw);
				
#add the frame to the vbox	
$vbox->pack_start($frame,TRUE,TRUE,4);
#make them all visable				
$vbox->show_all();	
return $vbox;
}

sub create_buffer {
	#-----------------------------------------------
	#a standard buffer will typically be:
	#1.) created
	#2.) tags added to;
	#3.) anchors, text, marks, and pixbuffs added to
	#-----------------------------------------------
	#create a net textbuffer
	my $buffer = Gtk2::TextBuffer->new();
	#create a bunch of standard tags
	$buffer->create_tag ("bold", weight => PANGO_WEIGHT_BOLD);
	$buffer->create_tag ("big", size => 20 * PANGO_SCALE);
	$buffer->create_tag ("italic", style => 'italic');
	$buffer->create_tag ("grey_foreground", foreground => "grey");
	#create a tag for the editable text (editable => TRUE)		
	my $tag = $buffer->create_tag ("editable",
					style =>'italic',
					weight => PANGO_WEIGHT_ULTRALIGHT,
					foreground => "blue",
					editable => TRUE,
					);
	#a created tag is for all practical purposes a hash with keys and values.
	#the "create_tag" method does not allow any additional keys, other than a standard set.
	#here we add a key and value to the $tag hash JUST after creation. This will later be used
	#when we check if the cursor must change.
	$tag->{pointer} = "edit";
	
	#we get the pointer to the start of the buffer, and add some content.
	#after every addition, this pointer ($iter) will be pointing to
	#a new place in the buffer. This works fine for sequencial additions
	my $iter = $buffer->get_start_iter;
	#tags is a list, thus they can be stacked to get desired results.
	$buffer->insert_with_tags_by_name ($iter, "Question:", "bold","big","grey_foreground");
	#pixbuffs can also be inserted into the buffer
	$buffer->insert_pixbuf ($iter,  Gtk2::Gdk::Pixbuf->new_from_file ("./pix/tux.png"));
	$buffer->insert_with_tags_by_name($iter, "\nDo you like Gtk2-Perl?\n\n","grey_foreground");
	#anchors are places where widgets can attach to
	$check_anchor = $buffer->create_child_anchor ($iter); 
	#our editable text
	$buffer->insert_with_tags_by_name ($iter, "\"Oh, yes my dear, its quite alright, I hear the tinkle of a bell!\"", "editable");
	$buffer->insert_with_tags_by_name($iter, "\n\n","grey_foreground");
	$submit_anchor = $buffer->create_child_anchor ($iter); 
	
	#return the finished buffer
	return $buffer;

}

sub motion_notify_event{
	
	my ($text_view, $event) = @_;
	
	#we have to discover where in the buffer the mouse currently
	#roams
	my ($x, $y) = $text_view->window_to_buffer_coords ( 
                                         'widget', #GTK_TEXT_WINDOW_WIDGET,
                                         $event->x, $event->y);
	#when we have the pointer co-ordinates within the buffer, 
	#we can do extra processing
	&determine_pointer($text_view,$x,$y);
	
	#this is a must to ensure the continuaty of 
	# recording the pointer position
	$text_view->window->get_pointer;
	return FALSE;	
}


  sub determine_pointer {
  
  #this sub will determine the iter where the mouse points at
  #in the textbuffer. Then it will check the iter's tags and 
  # if it finds the interesting one, change the cursor
  my ($text_view, $x, $y) = @_;
  
  my $hovering = FALSE;
  
  #get the textbuffer
  my $buffer = $text_view->get_buffer;
  	#determine which iter is at the x and y points where the mouse
	#currently sits at
	my $iter = $text_view->get_iter_at_location ($x, $y);
	#get all the tags associated with this iter
	#step througk them to check if one is a key 
	#with value "pointer" 	
	foreach my $tag ($iter->get_tags) {
      if ($tag->{pointer}) {
          $hovering = TRUE;
          last;
      }
  }
	#check if we need to change the cursor.
	#this will only execute when there is a change
	if ($hovering != $hovering_over_link){
      		$hovering_over_link = $hovering;

      			$text_view->get_window ('text')->set_cursor
			
		#compact conditional statement
      		($hovering_over_link ? $pencil_cursor : $point_cursor);
    	}
  }
