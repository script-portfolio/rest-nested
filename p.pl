#!/usr/bin/perl

use Mojolicious::Lite;
use DBI;
use DBD::SQLite;
use JSON;
use Data::Dumper;
use Data::Printer;

my $dbfile = 'dbcomment.sqlite';

helper comment_scope=> sub {
    my $self = shift;
    my $id = shift;
    my $hash = $self->db->selectall_hashref(
        "select id,id0,body from comments where id=$id or id0=$id",'id'); 
    delete $hash->{$id}->{id}; # delete redundant data
    return $hash;
};

## the same as above. withot info fields
helper comment_id_scope=> sub {
    my $self = shift;
    my $id = shift;
    my $hash = $self->db->selectall_hashref(
        "select id,id0 from comments where id=$id or id0=$id",'id'); 
    delete $hash->{$id}->{id}; # delete redundant data
    return $hash;
};

helper build_thread => sub {
    my $self = shift;
    my $id = shift;
    my $hash = $self->comment_scope($id);
    my $root = $hash->{$id};
    delete $root->{id0};

    foreach my $subcomment ( grep $_ !=  $id, keys %$hash ) {
        my $tmp = delete $hash->{$subcomment};
        my $subid = $tmp->{id};
        my $dive = $self->build_thread( $subid );
        delete $dive->{$subid}->{id0}; # delete redundant data
        push @{ $root->{subc} }, $dive;
    }
    return $hash;
};

## the same as above but slighly other
helper build_id_thread => sub {
    my $self = shift;
    my $id = shift;
    my $hash = $self->comment_id_scope($id);
    my $ret;
    map { $ret .= $self->build_id_thread($_). ',' } grep $_ !=  $id, keys %$hash;
    $ret .= $id;
    return  $ret;
};

my $dbh;
helper db => sub {
    return $dbh if $dbh and -f $dbfile;

    # we would like to delete database file 'on-fly' (quick restart)
    $dbh->disconnect if $dbh and ! -f $dbfile;

    $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile", undef,undef);
    $dbh->do("
        CREATE TABLE IF NOT EXISTS comments (
            id   INTEGER  PRIMARY KEY AUTOINCREMENT,
            id0  INTEGER, -- subcomments control. 0 - parent.
            body VARCHAR(255) ); " ) or die $dbh->errstr;
    return $dbh;
};

get '/:id' => { id=>0 } => sub {
    my $self = shift;
    my $id = $self->param('id');

    ##  ... Получение списка всех комментариев к статье по id
    ## id must be present
    # todo: we can show all structure for all records (nested). For id=0 case.
    return $self->render( text=>'Usage: GET ...uri.../id. # id != 0 !!') unless $id;


    # start recurse
    my $hash = $self->build_thread($id);

    # multi representation mechanizm in Mojolicious framework
    return $self->respond_to( 
                text=>{  text=>Dumper $hash },
                any =>{  json=>$hash } );
};


post '/:id' => { 'id'=>0 } => sub {
    my $self = shift;

    my $parent_id = $self->param('id');
    my @data = $self->param;
    my $body = (grep $_ ne 'id', @data)[0];


    # 1. it have to be ORM methodology. may be.
    # 2. todo: check: is there parent record ?
    my $ret = $self->db->do( 
         'INSERT INTO comments (id0,body) VALUES ('.
         $parent_id. ','.
         $self->db->quote( $body ). ')' ) or die $self->db->errstr;

    my $lid = $self->db->sqlite_last_insert_rowid();
    return $self->render( text=>
            ($parent_id ? '' : 'Sub')."Comment inserted [id=$lid]" );
};


del '/:id' => { id=>0 } => sub {
    my $self = shift;
    my $id = $self->param('id');
    return $self->render( text=>'Usage: DELETE ...uri.../id. # id != 0 !!') unless $id;

    # start recursion    
    my $list = $self->build_id_thread($id);
    my $ret = $self->db->do( "DELETE FROM comments WHERE id IN ($list)" ) or die $self->db->errstr;

    return $self->render( text=>'Deleted: '.$list );
};

app->start;
