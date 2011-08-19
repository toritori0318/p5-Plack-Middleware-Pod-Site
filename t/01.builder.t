use strict;
use Test::More;

use Plack::Builder;
use Plack::Test;
use Plack::Middleware::Pod::Site;
use File::Temp;

{
    my $dir = File::Temp::tempdir( CLEANUP => 1 );
    my $app = builder {
        enable 'Pod::Site',
            path => '/server-pod-test/',
            allow=>'0.0.0.0/0',
            root => $dir,
            module_roots => ['t/extlib/perl5/lib'],
            name => 'podsitetest';
        sub { [200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ]] };
    };
    test_psgi
        app => $app,
        client => sub {
            my $cb = shift;
            my $req = HTTP::Request->new(GET => "http://localhost/server-pod-test/");
            my $res = $cb->($req);
            like( $res->content, qr{<h3>podsitetest</h3>} );
            like( $res->content, qr{<a href="PodSiteTest.html">PodSiteTest</a>} );
        };
}

done_testing;
