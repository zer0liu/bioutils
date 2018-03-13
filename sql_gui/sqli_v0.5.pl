#!/usr/bin/perl

=head1 NAME

    sqlif.pl - A simple SQL interface.

=head1 DESCRIPTION

    This is a simple GUI interface for SQLite3 database.

    Users are able to input a set of data and a SQL statement to query the
given database.

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.01    2011-04-28
    0.50    2011-05-02

=cut

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Gtk2 '-init';
use Gtk2::GladeXML;
use Gtk2::Pango;

use DBI;
use Switch;

# use Data::Dumper;

use vars qw($dbh); # $sth $ret);
use vars qw($curdb);    # Current database
use vars qw($flg_tvSQL_enter $flg_tvData_enter);    # Whether TextView 'tviewSQL' and 'tviewInputData' entered

# Init global variable
$curdb = 'SQLite3';

# Load glade xml file
my $gladexml = Gtk2::GladeXML->new('interface2.glade');
$gladexml->signal_autoconnect_from_package('main');

my $winMain = $gladexml->get_widget('winMain');

# Other widgets
my $nbookDB = $gladexml->get_widget('nbookDB');

# widget on page 'SQLite3'
my $entrySQLiteFilename = $gladexml->get_widget('entrySQLiteFilename');

# widgets on page 'PostgreSQL'
my $entryPgHost   = $gladexml->get_widget('entryPgHost');
my $entryPgPort   = $gladexml->get_widget('entryPgPort');
my $entryPgDBname = $gladexml->get_widget('entryPgDBname');
my $entryPgUser   = $gladexml->get_widget('entryPgUser');
my $entryPgPasswd = $gladexml->get_widget('entryPgPasswd');

# widget TextViews
my $tviewSQL = $gladexml->get_widget('tviewSQL');

my $tviewInputData = $gladexml->get_widget('tviewInputData');

my $tviewResult = $gladexml->get_widget('tviewResult');

my $tviewOutput = $gladexml->get_widget('tviewOutput');

$winMain->show_all();

Gtk2->main;

######################################################################
#
#                             Subroutines
#
######################################################################

=begin
    Desc:   Create TextView 'tviewOutput' tags
=cut

sub initTViewOutputTags {
=begin
    my $buffer = $tviewOutput->get_buffer;

    my $tag_table = $buffer->get_tag_table;

    my $tag_blue = $buffer->create_tag('fg_blue', foreground => 'blue');

    my $tag_red = $buffer->create_tag('fg_red', foreground => 'red');

    $tag_table->add($tag_blue);
    $tag_table->add($tag_red);
=cut
    return;

}


=begin
    Desc:   connect to database
=cut

sub connDB {
    # if a database already connected and activated
    return if ( $dbh->{'Active'} );

    my $ret;    # For connect to a SQLite3 database.

    switch ( $curdb ) {
        case 'SQLite3'  { connSQLite3(); }
        case 'PostgreSQL'   { connPg(); }
        else { dlgError("No current database given.\nMay Not happened!\n"); }
    }

    return;
}

=begin
    Desc:   Disconnect to database
=cut

sub disconnDB {
    eval {
        $dbh->disconnect if ($dbh);
    };
    if ($@) {
        # errOutput( $dbh->errstr );
        errOutput( "$DBI::errstr" );

    }

    return;
}

=begin
    Desc:   Connect to a SQLite3 database
=cut

sub connSQLite3 {
    # Get SQLite3 database filename
    my $fdb = $entrySQLiteFilename->get_text;

    # if '$fdb' does NOT exits, create?
    # This is SQLite3 special problem
    unless (-e $fdb) {
        dlgWarn("Database file '$fdb' does NOT exist.\nCreate a new database?\n");
    }

    unless ( $fdb ) {   # No file specified
        # dlgError("Please choose a SQLite3 database file first!\n");
        errOutput("Please choose a SQLite3 database file first!\n");
        return;
    }

    # Now connecting
    eval {
        $dbh = DBI->connect(
            "dbi:SQLite:dbname=$fdb",
            "", "",
            {
                AutoCommit => 1,
                RaiseError => 1,
                PrintError => 0,
            }
        );
    };
    
    if ( $@ ) {
        # dlgError($@);
        errOutput( $DBI::errstr );
        return;
    }
    
    # return $dbh;
    return;
}

=begin 
    Desc:   Connect to a PostgreSQL database
=cut

sub connPg {
    # if a database already connected and activated
    # return if ($dbh->{'Active'} );
    
    # Get connection parameters
    my $host = $entryPgHost->get_text;
    my $port = $entryPgPort->get_text;
    my $db   = $entryPgDBname->get_text;
    my $user = $entryPgUser->get_text;
    my $pwd  = $entryPgPasswd->get_text;

    unless ($db) {
        errOutput("Please give a database name.");
        return;
    }

    # Connect to database
    eval {
        $dbh = DBI->connect(
            "dbi:Pg:dbname=$db;host=$host;port=$port",
            $user, $pwd,
            {
                AutoCommit => 1,
                RaiseError => 1,
                PrintError => 0,
            }
        );
    };
    if ( $@ ) {
        # errOutput( $DBI::errstr );
        errOutput( "$DBI::errstr" );
    }
}

=begin
    Desc:   Initialize TextView display to grey and italic.
=cut

sub initTView {
    my ($tview) = @_;
    
    my $buffer = $tview->get_buffer;
    
    # Set tag
    $buffer->create_tag('fg_grey', foreground => 'grey', style => 'italic');
    
    my ($start, $end) = $buffer->get_bounds;
    
    $buffer->apply_tag_by_name('fg_grey', $start, $end);
}

=begin
    Desc:   Clear TextView contents
=cut

sub clearTView {
    my ($tview) = @_;
    
    my $buffer = $tview->get_buffer;
    $buffer->set_text('');
    
    return;
}

=begin
    Desc:   Get SQL statement and the number of '?' in the SELECT statement
=cut

sub getSQLInfo {
    my $sql_buf = $tviewSQL->get_buffer;
    my ($sql_start, $sql_end) = $sql_buf->get_bounds;
    my $sql = $sql_buf->get_text($sql_start, $sql_end, FALSE);

    my $tmp_sql = $sql;
    my $num = ( $tmp_sql =~ s/\?//g );

    # DEBUG
    return ($sql, $num);
}

=begin
    Desc:   Get input data into an array
=cut

sub getInputData {
    my $data_buf = $tviewInputData->get_buffer;
    my ($data_start, $data_end) = $data_buf->get_bounds;
    my $data_str = $data_buf->get_text($data_start, $data_end, FALSE);

    # If no input data
    return (undef, 0) unless ($data_str);

    # DEBUG
    # print '-'x60, "\n", $data_str, "\n", '-'x60, "\n";
    
    my (@data, $col_num);

    my @rows = split(/\n/, $data_str);

    for my $row ( @rows ) {
        next if ($row =~ /^#/);
        next if ($row =~ /^\s*$/);
        chomp($row);
        
        my @cols = split(/\t/, $row);

        push @data, \@cols;
    }

    $col_num = scalar @{ $data[0] };

    return (\@data, $col_num);
}

=begin
    Desc:   Database query
=cut

sub queryDB {
    # DEBUG
    # print '-'x60, "\n", $dbh, "\n", '-'x60, "\n";
    return unless ( $dbh->{ 'Active' } );

    my ($sql, $rh_data) = @_;

    my ($sth, $ret);
    
    my $fetched_rows = 0;

    if ($rh_data) { # There are data available
        for my $rh_row ( @{ $rh_data } ) {
            eval {
                $sth = $dbh->prepare($sql);
        
                $ret = $sth->execute( @{$rh_row} );
            };
            if ( $@ ) {
                # dlgError($@);
                # errOutput($@);
                errOutput($dbh->errstr);

                return;
            }
        
            $fetched_rows += dispResult($sth);
        }
    }
    else {  # do query directly
        eval {
            $sth = $dbh->prepare($sql);

            $ret = $sth->execute();
        };
        if ($@) {
            errOutput($dbh->errstr);

            return;
        }

        $fetched_rows += dispResult($sth);
    }

    dispOutput("$fetched_rows rows fetched.");
    
    return ($sth, $ret);
}

=begin
    Desc:   Show an Error dialogue
=cut

sub dlgError {
    my ($msg) = @_;
    
    my $dlg = Gtk2::MessageDialog->new(
        undef,
        'modal',
        'error',
        'ok',
        $msg,
    );
    
    if ('ok' eq $dlg->run) {}
    
    $dlg->destroy;
    
    return;
}

=begin
    Desc:   Show a warning dialogue
=cut

sub dlgWarn {
    my ( $msg ) = @_;
    my $ret;

    my $dlg = Gtk2::MessageDialog->new(
        undef,
        'modal',
        'warning',
        'yes-no',
        $msg,
    );

    if ( 'yes' eq $dlg->run ) {
        $ret = 1;
    }
    else {
        $ret = 0;
    }

    $dlg->destroy;

    return $ret;
}

=begin
    Desc:   Display query result in TextViewResult
=cut

sub dispResult {
    my ($sth) = @_;
    
    my $rows = 0;

    # Clear previous contents
    # clearTView($tviewResult);
    
    my $buffer = $tviewResult->get_buffer;

    # Use Monospace font
    unless ( $buffer->get_tag_table->lookup('family_mono') ) {
        my $tag_red = $buffer->create_tag('family_mono', family => 'Monospace');
    }

    # Display column name
    my $ra_col_names = $sth->{'NAME'};
    my $end = $buffer->get_end_iter;
    my $header = '# ' . join("\t", @{ $ra_col_names }) . "\n";

    $buffer->insert_with_tags_by_name($end, $header, 'family_mono');

    # $buffer->insert($end, $header);
    
    # Display result in 'tviewResult' in rows one by one
    while (my @row = $sth->fetchrow_array) {
        $end = $buffer->get_end_iter;
        
        my $str = join("\t", @row) . "\n";
        
        # $buffer->insert($end, $str);
        $buffer->insert_with_tags_by_name($end, $str, 'family_mono');

        $rows++;
    }

    # Use an empty line to seperate records
    $end = $buffer->get_end_iter;
    $buffer->insert($end, "\n");

    # Output fetched rows
    # dispOutput("$rows records fetched.");
    return $rows;
}

=begin
    Desc:
=cut

sub dispOutput {
    my ($info) = @_;
    $info .= "\n";

    my $buffer = $tviewOutput->get_buffer;

    unless ( $buffer->get_tag_table->lookup('fg_blue') ) {
        my $tag_blue = $buffer->create_tag('fg_blue', foreground => 'blue');
    }

    my $end = $buffer->get_end_iter;

    $buffer->insert_with_tags_by_name($end, $info, 'fg_blue');

    # $buffer->insert($end, $info);

    return;
}

=begin
    Desc:   Display ERROR information in 'tviewOutput'
=cut

sub errOutput {
    my ($info) = @_;

    $info = 'Error: ' . $info ."\n";

    my $buffer = $tviewOutput->get_buffer;

    unless ( $buffer->get_tag_table->lookup('fg_red') ) {
        my $tag_red = $buffer->create_tag('fg_red', foreground => 'red');
    }

    my $end = $buffer->get_end_iter;

    $buffer->insert_with_tags_by_name($end, $info, 'fg_red');
    
    #$buffer->insert($end, $info);

    return;
}

sub on_winMain_show {
    initTView($tviewSQL);
    initTView($tviewInputData);
    
    return;
}

sub on_winMain_destroy {
    # Disconnect database
    $dbh->disconnect if ( $dbh->{'Active'} );
    Gtk2->main_quit;
}

sub on_winMain_activate_default {
    # init tviewOutput tags
    initTViewOutputTags();
}


=begin

=cut

sub  on_btnSQLiteFileOpen_clicked {
    my $file_chooser = Gtk2::FileChooserDialog->new(
        'Select SQLite3 Database File',
        undef,
        'open',
        'gtk-cancel' => 'cancel',
        'gtk-ok' => 'ok',
    );

    my $filename;

    if ('ok' eq $file_chooser->run){    
       $filename = $file_chooser->get_filename;
    }
    
    $file_chooser->destroy;
    
    $entrySQLiteFilename->set_text($filename) if ($filename);
    
    return;
}

=begin
    Desc:   Clear tviewSQL contents when get focus in
=cut

sub on_tviewSQL_focus_in_event {
    unless ( $flg_tvSQL_enter ) {
        clearTView($tviewSQL);

        $flg_tvSQL_enter = TRUE;
    }
    
    return;
}

=begin
    Desc:   Clear tviewInputData contents when get focus in
=cut

sub on_tviewInputData_focus_in_event {
    unless ( $flg_tvData_enter ) { 
        clearTView($tviewInputData);

        $flg_tvData_enter = TRUE;
    }
    
    return;
}

=begin
    Desc:   Execute SQL query.
=cut

sub on_btnExec_clicked {
    # Check whether 'tviewSQL' and 'tviewInputdata' changed
    unless ($flg_tvSQL_enter) {
        errOutput('Please input SQL query statement first!');

        return;
    }

    # If 'tviewInputData' has not been touched, clear
    # This will avoid to get the sample tviewInputData contents
    clearTView($tviewInputData) unless ($flg_tvData_enter); 

    # Clear previous query result
    clearTView($tviewResult);
    
    # Also clear previous query output
    clearTView($tviewOutput);
    
    my ($sql, $sql_param_num) = getSQLInfo();

    my ($rh_data, $data_col_num) = getInputData();

    if ( $sql_param_num != $data_col_num ) {
        errOutput("The numbers of query parameter and data columns don't match!");
        return;
    } 

    # Connecting to database
    connDB();
    
    return unless ($dbh);
    
    # my $sql_buf = $tviewSQL->get_buffer;
    # my ($sql_start, $sql_end) = $sql_buf->get_bounds;
    # my $sql = $sql_buf->get_text($sql_start, $sql_end, FALSE);
    
    queryDB($sql, $rh_data);

    # return unless ($sth);
    
    # dispResult($sth);
}


=begin
    Desc:   Notebook 'nbookDB' event. 
            - Get current database, 'SQLite3' or 'PostgreSQL'
            - Disconnect to previous database.
            - Clear all 4 TextViews.
=cut

sub on_nbookDB_switch_page {
    my $cur_page_id = $nbookDB->get_current_page;
    
    # Use page label for current database
    $curdb = $nbookDB->get_tab_label( $nbookDB->get_nth_page($cur_page_id) )->get_label;

    # DEBUG
    # print "From nbook switch\n";
    #print "Current page: ", $cur_page, "\n";
    # my $page = $nbookDB->get_nth_page($cur_page);
    # my $label = $nbookDB->get_tab_label($page);
    # print $label->get_label, "\n";
    # print "Current page label: ", $nbookDB->get_tab_lable($nbookDB->get_nth_page($cur_page) ), "\n";
    # print Dumper( @_ ), "\n";

    # Disconnect database
    if ($dbh) {
        dispOutput("Disconnecting current database ...\n");

        disconnDB();

        # Clear all TextViews
        clearTView($tviewSQL);
        clearTView($tviewInputData);
        clearTView($tviewResult);
        clearTView($tviewOutput);
    }

    return;
}

=begin
    Desc:   Clear TextView 'tviewSQL' contents
=cut

sub on_btnClearSQL_clicked {
    clearTView($tviewSQL);
    return;
}

=begin
    Desc:   Load data from an out file
=cut

sub on_btnLoadData_clicked {
    my $file_chooser = Gtk2::FileChooserDialog->new(
        'Select Input Data File',
        undef,
        'open',
        'gtk-cancel' => 'cancel',
        'gtk-ok' => 'ok',
    );

    my $filename;

    if ('ok' eq $file_chooser->run) {    
       $filename = $file_chooser->get_filename;
    }

    $file_chooser->destroy;

    return unless ( $filename );
    
        
    eval {
        open(IN, $filename);
    };
    if ($@) {
        errOutput("$filename: $!");
        
        return;
    }
    
    # Read $filename contents into a string
    my $str;
    
    while (<IN>) {
        $str .= $_;
    }
    
    close IN;
    
    # Cleat tviewInputData
    clearTView( $tviewInputData );
    
    # Display data
    my $buffer = $tviewInputData->get_buffer;
    
    $buffer->set_text( $str );
    
    return;
}

=begin
    Desc:   Save result into file.
=cut

sub on_btnSave_clicked {
    my $file_chooser = Gtk2::FileChooserDialog->new(
        'Save Result to File',
        undef,
        'save',
        'gtk-cancel' => 'cancel',
        'gtk-ok' => 'ok',
    );
    
    $file_chooser->set_current_name('result.txt');

    my $filename;

    if ('ok' eq $file_chooser->run) {    
       $filename = $file_chooser->get_filename;
    }
    
    $file_chooser->destroy;
    
    
    eval {
        open(OUT, ">", $filename);
    };
    if ($@) {
        errOutput("$filename: $!");
        
        return;
    }
    
    my $buffer = $tviewResult->get_buffer;
    
    my ($start, $end) = $buffer->get_bounds;
    
    my $text = $buffer->get_text($start, $end, FALSE);
    
    # Output to file
    print OUT $text;
    
    close OUT;
    
    dispOutput("File $filename saved OK.");
    
    return;
}

=begin
    Desc:   Clear TextView 'tviewInputData' contents
=cut

sub on_btnClearData_clicked {
    clearTView($tviewInputData);
    return;
}

=begin
    Desc:   Disconnect to database if connection paramters changed
=cut

sub on_entrySQLiteFilename_changed {
    disconnDB();

    return;
}

sub on_entryPgHost_changed {
    disconnDB();

    return;
}

sub on_entryPgPort_changed {
    disconnDB();

    return;
}

sub on_entryPgDBname_changed {
    disconnDB();

    return;
}

sub on_entryPgUser_changed {
    disconnDB();

    return;
}

sub on_entryPgPasswd_changed {
    disconnDB();

    return;
}

__END__
