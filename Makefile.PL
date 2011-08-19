use 5.014001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Plack::Middleware::Pod::Site',
    VERSION_FROM      => 'lib/Plack/Middleware/Pod/Site.pm', # finds $VERSION
    PREREQ_PM     => {
        'Plack::Middleware'  => 0,
        'Net::CIDR::Lite'    => 0,
        'Pod::Site'          => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Plack/Middleware/Pod/Site.pm', # retrieve abstract from module
       AUTHOR         => 'torii <torii@local>') : ()),
);

