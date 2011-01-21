
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Lightweight To-The-Point Email',
  'AUTHOR' => 'Al Newkirk <awncorp@cpan.org>',
  'BUILD_REQUIRES' => {},
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Emailesque',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Emailesque',
  'PREREQ_PM' => {
    'Authen::SASL' => '0',
    'Email::AddressParser' => '1',
    'Email::Stuff' => '2.102',
    'Hash::Merge' => '0.12',
    'IO::Socket::SSL' => '0',
    'Net::SMTP::SSL' => '0',
    'Net::SMTP::TLS' => '0',
    'Net::SSLeay' => '0'
  },
  'VERSION' => '1.110210',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



