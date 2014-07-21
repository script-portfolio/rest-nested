#!/usr/bin/perl

use Mojolicious::Lite;
use Data::Dumper;

get '/:id' => sub {
    my $self = shift;
    return $self->render( text=>'get' );
};

post '/' => sub {
    my $self = shift;
    return $self->render( text=>Dumper caller() );
};


app->start;
