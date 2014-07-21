#!/usr/bin/perl

use Mojolicious::Lite;
use DBI;
#use DBD::SQLite;
use JSON;
use Data::Dumper;

my $dbfile = 'dbcomment.sqlite';

helper comment_scope=> sub {
    my $self = shift;
    my $id = shift;
    my $hash = $self->db->selectall_hashref(
        "select * from comments where id=$id or id0=$id",'id'); 
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

my $dbh;
helper db => sub {
    return $dbh if $dbh;
    ## sudo apt-get install libdbd-sqlite3-perl
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
    return $self->render( text=>'Usage: GET ...uri.../id. # id != 0 !!') unless $id;


    # start recurse
    my $hash = $self->build_thread($id);

    my $t = Dumper $hash;
    return $self->respond_to( 
              #  json=>{ json => encode_json( $hash ) },
              #  text=>{ text=> $t  },
                any=>{ $self->render( text=>'hi'  ) } );

};

# 
post '/:id' => { 'id'=>0 } => sub {
    my $self = shift;
    # it have to validate JSON consistency (eval solution)
    my @data = $self->param;

    my $parent_id = $self->param('id');
    my $ref = decode_json( $data[1] );

    #say 'ParId: ', $parent_id;
    #say 'ref: ', $ref;

    # 1. it have to be ORM methodology. may be.
    # 2. todo: check: is there parent record ?
    $self->db->do( 
         'INSERT INTO comments (id0,body) VALUES ('.
         $parent_id. ','.
         $self->db->quote( $ref->{body} ).  ')' ) or die $self->db->errstr;
    
#
    return $self->render( text=>'Post: ' );
    #return $self->render( text=>'Post: '.Dumper $self->param() );
};


del '/:id' => { id=>'nill' } => sub {
    my $self = shift;
    return $self->render( text=>'Delete: '.Dumper caller() );
};



app->start;
