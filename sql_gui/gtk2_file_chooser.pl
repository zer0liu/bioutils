#! /usr/bin/perl -w

use strict;
use Gtk2 '-init';
use Glib qw/TRUE FALSE/; 

#standard window creation, placement, and signal connecting
my $window = Gtk2::Window->new('toplevel');
$window->signal_connect('delete_event' => sub { Gtk2->main_quit; });
$window->set_border_width(5);
$window->set_position('center_always');

#add and show the vbox
$window->add(&ret_vbox);
$window->show();

#our main event-loop
Gtk2->main();

sub ret_vbox {

my $vbox = Gtk2::VBox->new(FALSE,5);

    #***************************************
    #Show the filechooserbuttons (open and select-folder action types)
    my $frm_fl_chooser_button = Gtk2::Frame->new('Gtk2::FileChooserButton');
    $frm_fl_chooser_button->set_border_width(5);

        my $hbox_fl_chooser_button = Gtk2::HBox->new(FALSE,5);
        $hbox_fl_chooser_button->set_border_width(10);

    #Open a file dialog button----->
            my $fc_btn_file =Gtk2::FileChooserButton->new ('select a file' , 'open');
            $fc_btn_file->set_filename("/etc/passwd");
        $hbox_fl_chooser_button->pack_start($fc_btn_file,TRUE,TRUE,6);

    #Open a folder dialog button---->
            my $fc_btn_folder =Gtk2::FileChooserButton->new ('select a folder' , 'select-folder');
        $hbox_fl_chooser_button->pack_start($fc_btn_folder,TRUE,TRUE,6);

    $frm_fl_chooser_button->add($hbox_fl_chooser_button);
$vbox->pack_start($frm_fl_chooser_button,FALSE,FALSE,6);

    #***************************************
    #Show the filechooserdialog action types (open save select-folder create-folder)
    my $frm_fl_chooser_dialog = Gtk2::Frame->new('Gtk2::FileChooserDialog Incarnations');

        my $hbox_fl_chooser_dialog = Gtk2::HBox->new(FALSE,5);
        $hbox_fl_chooser_dialog->set_border_width(10);

    #Open---->
            my $btn_open            = Gtk2::Button ->new('_Open');
            $btn_open->signal_connect('clicked' => 
                        sub{ show_chooser('File Chooser type open','open',ret_png_filter()) });
        $hbox_fl_chooser_dialog->pack_start($btn_open,TRUE,TRUE,6);

    #Save---->
            my $btn_save            = Gtk2::Button->new('_Save');
            $btn_save->signal_connect('clicked' => 
                        sub{ show_chooser('File Chooser type save','save') });
        $hbox_fl_chooser_dialog->pack_start($btn_save,TRUE,TRUE,6);

    #Select Folder---->
            my $btn_select_folder   = Gtk2::Button->new('S_elect Folder');
            $btn_select_folder->signal_connect('clicked' => 
                        sub{ show_chooser('File Chooser type select-folder','select-folder') });
        $hbox_fl_chooser_dialog->pack_start($btn_select_folder,TRUE,TRUE,6);

    #Create Folder---->
            my $btn_create_folder   = Gtk2::Button->new('_Create Folder');
            $btn_create_folder->signal_connect('clicked' => 
                        sub{ show_chooser('File Chooser type create-folder','create-folder') });
        $hbox_fl_chooser_dialog->pack_start($btn_create_folder,TRUE,TRUE,6);

       $frm_fl_chooser_dialog->add($hbox_fl_chooser_dialog);
$vbox->pack_start($frm_fl_chooser_dialog,FALSE,FALSE,6);


$vbox->show_all();
return $vbox;
}

sub show_chooser {
#---------------------------------------------------
#Pops up a standard file chooser--------------------
#Specify a header to be displayed-------------------
#Specify a type depending on your needs-------------
#Optionally add a filter to show only certain files-
#will return a path, if valid----------------------
#---------------------------------------------------

    my($heading,$type,$filter) =@_;
#$type can be:
#* 'open' 
#* 'save' 
#* 'select-folder'
#* 'create-folder' 
    my $file_chooser =  Gtk2::FileChooserDialog->new ( 
                            $heading,
                            undef,
                            $type,
                            'gtk-cancel' => 'cancel',
                            'gtk-ok' => 'ok'
                        );
    (defined $filter)&&($file_chooser->add_filter($filter));
    
    #if action = 'save' suggest a filename
    ($type eq 'save')&&($file_chooser->set_current_name("suggeste_this_file.name"));

    my $filename;

    if ('ok' eq $file_chooser->run){    
       $filename = $file_chooser->get_filename;
       print "filename $filename\n";
    }

    $file_chooser->destroy;

    if (defined $filename){
        if ((-f $filename)&&($type eq 'save')) {
            my $overwrite =show_message_dialog( $window,
                                                'question'
                                                ,'Overwrite existing file:'."<b>\n$filename</b>"
                                                ,'yes-no'
                                    );
            return  if ($overwrite eq 'no');
        }
        return $filename;
    }
    return;
}

sub show_message_dialog {
#---------------------------------------------------
#you tell it what to display, and how to display it
#$parent is the parent window, or "undef"
#$icon can be one of the following: a) 'info'
#                   b) 'warning'
#                   c) 'error'
#                   d) 'question'
#$text can be pango markup text, or just plain text, IE the message
#$button_type can be one of the following:  a) 'none'
#                       b) 'ok'
#                       c) 'close'
#                       d) 'cancel'
#                       e) 'yes-no'
#                       f) 'ok-cancel'
#---------------------------------------------------

my ($parent,$icon,$text,$button_type) = @_;
  
my $dialog = Gtk2::MessageDialog->new_with_markup ($parent,
                    [qw/modal destroy-with-parent/],
                    $icon,
                    $button_type,
                    sprintf "$text");
    my $retval = $dialog->run;
    $dialog->destroy;
    return $retval;
}


sub ret_png_filter {
#----------------------------------------
#Returns a filter, filtering only png files
#----------------------------------------

    my $filter = Gtk2::FileFilter->new();
    $filter->set_name("Images");
    $filter->add_mime_type("image/png");
    
    return $filter;
}