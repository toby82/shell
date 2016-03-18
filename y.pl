#!/usr/bin/perl 
use feature 'say';
use YAML::Syck;
use Data::Dumper;
$YAML::Syck::SortKeys = 1;
$YAML::Syck::ImplicitTyping = 1;
$YAML::Syck::ImplicitUnicode = 1;
@args = ('salt','cc12.chinacloud.com','test.ping');
print system(@args);
exit 1;
$o = system(@args);

@so = split(/:/,$o);
print $so[0];
exit 0;

sub check_host {
    my @hosts = readpipe("salt-key");
    foreach $host (@hosts){
        if ($host =~ /\bcc|\bnn|\bnc|\bautodeploy\d*\.\S+/){
            @args = ('salt',$host,'test.ping');
            @outs = system(@args);
            #foreach $key (keys @outs){
                say @outs;
            #}
        }
    }
}

check_host;
exit 0 ;
my %stooges = (
    Moe => 'Howard',
    Larry => 'Fine',
    Curly => 'Howard',
    Iggy => 'Pop',
);
=begin
$count = keys %stooges;
foreach (keys %stooges){
    if ( $_ =~ /^M\w+/) {
        say $_;
    }
}

say $count;
#print $stooges{Moe};


my $ds = {
    a => [4, 5, 6, 7],
    s => "hello",
};
DumpFile("hello.yml", $ds);
=cut

=begin
sub w_file{
    open(fh,">conf.sls.b")
    while(<fh>){
        print 
    }
}
use YAML::XS 'LoadFile';
use feature 'say';

my $config = LoadFile('config.yaml');

# access the scalar emailName
my $emailName = $config->{emailName};

# access the array emailAddresses directly
my $firstEmailAddress = $config->{emailAddresses}->[0];
my $secondEmailAddress= $config->{emailAddresses}->[1];

# loop through and print emailAddresses
for (@{$config->{emailAddresses}}) { say }

# access the credentials hash key values directly
my $username = $config->{credentials}->{username};
my $password = $config->{credentials}->{password};

# loop through and print credentials
for (keys %{$config->{credentials}}) {
    say "$_: $config->{credentials}->{$_}";
}
  open(my $fh, ">:encoding(UTF-8)", "out.yml");
  DumpFile($fh, $hashref);
=cut


my $conf = YAML::Syck::LoadFile('/root/shell/config.sls');

$key = $conf->{mg_nw}->{hosts}->{present};
$count = keys $key;
say $count;
foreach (keys $key){
    if ( $_ =~ /^cc\d*\.\S+/) {
        say $_;
    }
}

print %key;

print Dumper $conf;


open(fh,">conf.sls.b");
#print fh Dumper $conf;
$file = q(/root/conf.sls.a);
print fh Dump($conf);

if (($conf->{storage_type}) eq 'local'){
    print $conf->{storage_type};
    print $conf->{storage_network};
    $conf->{cinder_info}->{backend} = 'lvm';
    delete $conf->{cinder_info}->{gluster_mounts};
    delete $conf->{glance_info};
    delete $conf->{nova_info};
    print '#' x 50;
    print "\n";
}else {
    print 'x' x 50;
}
if ($conf->{allinone_enable} && $conf->{allinone_type} eq 'kvm'){
    print "allinone\n";
    delete $conf->{iaas_role}->{vmw_agent};
    $conf->{iaas_role}->{nc} = '.*nc|cc\S*\..*';
    $conf->{iaas_role}->{nn} = $conf->{mg_nw}->{hosts}->{present}->{'cc12.chinacloud.com'};
    $conf->{iaas_role}->{autodeploy} = $conf->{mg_nw}->{hosts}->{present}->{'cc12.chinacloud.com'};
    $conf->{iaas_role}->{cc} = $conf->{mg_nw}->{hosts}->{present}->{'cc12.chinacloud.com'};
    $conf->{glusterfs}->{enable} = "False";
    $conf->{ironic_info}->{install} = "n";
    $conf->{lun_info}->{enable} = "False";
    $conf->{ocfs2_cluster}->{enable} = "False";
    $conf->{cinder_info}->{lvm_enable} = "y";
}else{
    print "no allinone\n";
}
$outfile = "conf_out.txt";
DumpFile($outfile,$conf);
exit 0;
print fh Dump($conf);
print Dumper $conf;

print Dumper($conf);
say $conf->{storage_type};
say $conf->{allinone_type};
say $conf->{allinone_enable};
say $conf->{ha_enable};
say $conf->{storage_network};
say $conf->{ironic_info}->{install};
exit 0;
print Dumper($conf);
foreach $key (keys $conf){
    print "$key\n";
}
exit 0;
print $conf;
exit 0;
print Dumper($conf);