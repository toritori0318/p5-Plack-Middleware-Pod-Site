package Plack::Middleware::Pod::Site;

use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::App::File;
use Plack::Util::Accessor qw(path root allow module_roots base_uri name);
use Net::CIDR::Lite;
use Pod::Site;

our $VERSION = '0.01';

sub prepare_app {
    my $self = shift;

    if ( $self->allow ) {
        my $cidr = Net::CIDR::Lite->new();
        my @ip = ref $self->allow ? @{$self->allow} : ($self->allow);
        $cidr->add_any( $_ ) for @ip;
        $self->{__cidr} = $cidr;
    }

    my %params;
    $params{module_roots} = ($self->module_roots) ? $self->module_roots : 'lib';
    $params{doc_root}     = ($self->root) ? $self->root : 'podsite';
    $params{base_uri}     = ($self->base_uri) ? $self->base_uri : 'podsite';
    $params{name}         = ($self->name) ? $self->name : 'podsite';
    my $ps = Pod::Site->new(\%params);
    $ps->build;
}

sub call {
    my $self = shift;
    my $env  = shift;

    if ( ! $self->allowed($env->{REMOTE_ADDR}) ) {
        return [403, ['Content-Type' => 'text/plain'], [ 'Forbidden' ]];
    }
    my $res = $self->_handle_static($env);
    if ($res && not ($res->[0] == 404)) {
        return $res;
    }
    return $self->app->($env);
}

sub allowed {
    my ( $self , $address ) = @_;
    return unless $self->{__cidr};
    return $self->{__cidr}->find( $address );
}

sub _handle_static {
    my($self, $env) = @_;
    my $path_match = $self->path or return;
    my $path = $env->{PATH_INFO};

    return if $path !~ $path_match;

    $self->{file} ||= Plack::App::File->new({ root => $self->root || 'podsite/' });
    $path .= 'index.html' if $path =~ m{/$};
    my @paths = split /\//, $path;
    local $env->{PATH_INFO} = join('/', @paths[2..$#paths]); # rewrite PATH
    return $self->{file}->call($env);
}

1;
__END__

=head1 NAME

Plack::Middleware::Pod::Site - Build browsable HTML documentation for plack app

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
    enable "Plack::Middleware::Pod::Site",
        path => qr{^/server-pod/},
        root => 'podsite/',
        allow => [ '127.0.0.1', '192.168.0.0/16' ];

      $app;
  };


=head1 DESCRIPTION

Build browsable HTML documentation for plack app

=head1 CONFIGURATIONS

=over 4

=item path

  path => '/server-pod/',

location that displays pod site

=item allow

  allow => '127.0.0.1'
  allow => ['192.168.0.0/16', '10.0.0.0/8']

host based access control of a page of pod site

=item root (default : 'podsite/')

  root => '/path/to/dir'

Pod Site directory

=item module_roots (default : 'lib')

An array reference of directories to search for Pod files, or for the paths of
Pod files themselves. These files and directories will be searched for the Pod
documentation to build the browser.

=item doc_root (default : 'podsite')

Path to a directory to use as the site document root. This directory will be
created if it does not already exist.

=item base_uri (default : 'podsite')

Base URI for the Pod site. For example, if your documentation will be served
from F</docs/2.0/api>, then that would be the base URI for the site.

May be an array reference of base URIs. This is useful if your Pod site will
be served from more than one URL. This is common for versioned documentation,
where you might have docs in F</docs/2.0/api> and a symlink to that directory
from F</docs/current/api>. This parameter is important to get links from one
page to another within the site to work properly.

=item name (default : 'podsite')

The name of the site. Defaults to the name of the main module.

=back

=head1 AUTHOR

Tsuyoshi torii

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

