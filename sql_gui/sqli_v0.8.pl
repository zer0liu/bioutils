#!/usr/bin/perl

=head1 NAME

    sqlif.pl - A simple SQL interface.

=head1 DESCRIPTION

    This is a simple GUI interface for SQLite3 database.

    Users are able to input a set of data and a SQL statement to query the
    given database.
    
    For instance,
    
    - A table 'names'
    
        id  name    gendre  age
        ==  ====    ======  ====
        1	Jackson	M	15
        2	Joe	M	25
        3	Smith	M	20
        4	White	F	20
        5	Harris	F	14
    
    - SQL statement
        
        SELECT * FROM names WHERE name=? AND gendre=?
        
    - Input parameters
    
        Jackson M
        Smith   M
        Harris  F
    
    Note: Parameters will be seperated by a tab.

=head1 AUTHOR

    zeroliu-at-gmail-dot-com

=head1 VERSION

    0.01    2011-04-28
    0.50    2011-05-02
    0.80    2011-05-17  Use Gtk2::TreeView to display result.
    0.85    2011-05-18  Rebuild some codes.

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
use Smart::Comments;

use vars qw($dbh $sth $ret); # $sth $ret);
use vars qw($curdb);    # Current database

# Global variables:
# - Number of results
# - Result colunm titles
# - Result dataset
use vars qw($num_results @titles @results);

# Flags, whether TextView 'tviewSQL' and 'tviewInputData' entered
use vars qw($F_tvSQL_enter $F_tvData_enter);    

# Init global variable
$curdb = 'SQLite3';

# Load glade xml file and auto-connect signals
my $gladexml = Gtk2::GladeXML->new('interface3.glade');
$gladexml->signal_autoconnect_from_package('main');

# Main window
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

my $treeviewResult = $gladexml->get_widget('treeviewResult');

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
    Name:   connDB
    Desc:   connect to database
    Usage:  connDB
    Args:
    Return:
=cut

sub connDB {
    # if a database already connected and activated
    return if ( $dbh->{'Active'} );

    switch ( $curdb ) {
        case 'SQLite3'  { connSQLite3(); }
        case 'PostgreSQL'   { connPg(); }
        else { dlgError("No current database given.\nMay Not happened!\n"); }
    }

    return;
}

=begin
    Name:   disconnDB
    Desc:   Disconnect to database
    Usage:  disconnDB
    Args:
    Return:
=cut

sub disconnDB {
    eval {
        $dbh->disconnect if ( $dbh->{'Active'} );
    };
    if ($@) {
        # errOutput( $dbh->errstr );
        errOutput( "$DBI::errstr" );
    }

    return;
}

=begin
    Name:   connSQLite3
    Desc:   Connect to a SQLite3 database
    Usage:  connSQLite3
    Args:
    Return:
=cut

sub connSQLite3 {
    # Get SQLite3 database filename
    my $fdb = $entrySQLiteFilename->get_text;

    # No file specified
    unless ( $fdb ) {   
        # dlgError("Please choose a SQLite3 database file first!\n");
        errOutput("Please choose a SQLite3 database file first!\n");
        return;
    }

    # if '$fdb' does NOT exits, create?
    # This is SQLite3 special problem
    unless (-e $fdb) {
        dlgWarn("Database file '$fdb' does NOT exist.\nCreate a new database?\n");
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
    
    return;
}

=begin
    Name:   connPg
    Desc:   Connect to a PostgreSQL database
    Usage:  connPg
    Args:
    Return:
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
    
    return;
}

=begin
    Name:   initTView
    Desc:   Initialize TextView 'tviewSQL' and 'tviewInputData' display to 
            grey and italic.
    Usage:  initTView
    Args:
    Return:
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
    Name:   clearTView
    Desc:   Clear TextView contents
    Usage:  clearTView
    Args:
    Return:
=cut

sub clearTView {
    my ($tview) = @_;
    
    my $buffer = $tview->get_buffer;
    $buffer->set_text('');
    
    return;
}

=begin
    Name:   getSQLInfo
    Desc:   Get SQL statement in TextView 'tviewSQL', and parse the number of
            '?' in the SELECT statement
    Usage:  getSQLInfo
    Args:
    Return: SQL statement and the number of query parameters ('?')
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
    Name:   getInputData
    Desc:   Get input data in TextView 'tviewInputData' into an array
    Usage:  getInputData
    Args:
    Return: An array reference of data, and the number of columns of data.
            
            Structure of $ra_data:
            
            $rh_data = [
                [ A1, B1, C1, ... ],
                [ A2, B2, C2, ... ],
                ...
            ];
    Note:   This script won't check whether there are equal elements for every
            row.
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
    Name:   queryDB
    Desc:   Database query
    Usage:  queryDB( $sql, $rh_data )
    Args:   $sql        SQL statement, from TextView 'tviewSQL'
            $rh_data    Query parameters, from TextView 'inputData'
    Return: $sth and $ret
=cut

sub queryDB {
    # If database connection is not active
    return unless ( $dbh->{ 'Active' } );

    my ($sql, $rh_data) = @_;

#    my ($sth, $ret);
    
    my $fetched_rows = 0;

    if ($rh_data) { # There are data available
        # There may be multi-queries
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
        
            # $fetched_rows += dispResult($sth);
            fetchQueryResult();
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

        # $fetched_rows += dispResult($sth);
        fetchQueryResult();
    }

    dispOutput("$fetched_rows rows fetched.");
    
    return ($sth, $ret);
}

=begin
    Name:   fetchQueryResult
    Desc:   Fetch Result from SQL query handle
    Usage:  fetchQueryResult()
    Args:
    Return:
=cut

sub fetchQueryResult {
    while ( my @row = fetchrow_array( $sth ) ) {
        push @results, \@row;
        
        $num_results++;
    }
}

=begin
    Name:   fetchQueryTitle
    Desc:   Fetch titles of query result set
    Usage:  fetchQueryTitle()
    Args:
    Return:
=cut

sub fetchQueryTitle {
    @titles = $sth->{'NAME'};
    
    return;
}

=begin
    Name:   dlgError
    Desc:   Show an Error dialogue   
    Usage:  dlgError($msg)
    Args:   $msg, show message
    Return:
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
    Name:   dlgWarn
    Usage:  dlgWarn( $msg )
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
    Name:   dispResult
    Desc:   Display query result in TreeViewResult.
    Usage:  dispResult()
    Args:
    Return: Number of fetched and displayed rows.
=cut


sub dispResult {
    return unless ( fetchQueryTitle() );
    
    # Get column name
    my $ra_col_names = $sth->{'NAME'};

    my $col_num = scalar( @{ $ra_col_names} );

    # Create a list store
    my $list_store = Gtk2::ListStore->new( ('Glib::String') x $col_num );

    # $treeviewResult->set_model( $list_store );

    # Create columns
    # Display header
    my $idx = 0;
    for my $name ( @{ $ra_col_names } ) {
        my $treeviewcol = Gtk2::TreeViewColumn->new();

        my $text_render = Gtk2::CellRendererText->new();

        $treeviewcol->pack_start( $text_render, TRUE);
        $treeviewcol->set_attributes($text_render, 'text' => $idx);

        $treeviewcol->set_title($name);

        $treeviewResult->append_column( $treeviewcol );

        $idx++;
    }
    
    # Fetch query result
    while ( my @row = $sth->fetchrow_array ) {
        my $iter = $list_store->append();
        my $idx = 0;
    
#        $list_store->set($iter, $idx, $row[$idx] );
#        for my $cell ( @row ) {
#            $list_store->set(
#                $iter,
#                # $idx => $cell,
#                $idx, $cell,
#            );
#            $idx++;
#        }

        $list_store->set(
            $iter,
            0 => $row[0],
            1 => $row[1],
            2 => $row[2],
            3 => $row[3],
        );
    }

    $treeviewResult->set_model( $list_store );
    
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
    unless ( $F_tvSQL_enter ) {
        clearTView($tviewSQL);

        $F_tvSQL_enter = TRUE;
    }
    
    return;
}

=begin
    Desc:   Clear tviewInputData contents when get focus in
=cut

sub on_tviewInputData_focus_in_event {
    unless ( $F_tvData_enter ) { 
        clearTView($tviewInputData);

        $F_tvData_enter = TRUE;
    }
    
    return;
}

=begin
    Desc:   Execute SQL query.
=cut

sub on_btnExec_clicked {
    # Init global variables
    $num_results = 0;
    @titles      = ();
    @results     = ();
    
    # Check whether 'tviewSQL' and 'tviewInputdata' changed
    unless ($F_tvSQL_enter) {
        errOutput('Please input SQL query statement first!');

        return;
    }

    # If 'tviewInputData' has not been touched, clear
    # This will avoid to get the sample tviewInputData contents
    clearTView($tviewInputData) unless ($F_tvData_enter); 

    # Clear previous query result
    # clearTView($tviewResult);
    
    # ----- Here destroy ListStoreResult -----
    
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

    # Query database, and fetch result to global variables '$num_results',
    # '@results'
    return unless ( queryDB($sql, $rh_data) );

    dispResult();
    
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
        # clearTView($tviewResult);
        # ----- Here Destroy ListStoreResult -----

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
    
=begin  
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
=cut

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
