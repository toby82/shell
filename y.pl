#!/usr/bin/perl 
use YAML::XS;
use Data::Dumper;
my $conf = YAML::XS::LoadFile('/root/shell/config.sls');
print Dumper($conf);