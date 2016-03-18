#!/usr/bin/env perl
use Tie::File;
$nova_conf = '/etc/nova/nova.conf';
$ceilometer_conf = '/etc/ceilometer/ceilometer.conf';
$cinder_conf = '/etc/cinder/cinder.conf';
$TEMPLATE_VCIP = $ENV{TEMPLATE_VCIP};
$TEMPLATE_VCUSER = $ENV{TEMPLATE_VCUSER};
$TEMPLATE_VCPASSWD = $ENV{TEMPLATE_VCPASSWD};
$TEMPLATE_CC_IP = $ENV{TEMPLATE_CC_IP};
$TEMPLATE_VCCLUSTER = $ENV{TEMPLATE_VCCLUSTER};
$TEMPLATE_NCDRIVER = $ENV{TEMPLATE_NCDRIVER};
$TEMPLATE_HOSTNAME = $ENV{TEMPLATE_HOSTNAME};

sub update_template{
    tie @lines, 'Tie::File', @_;
    for(@lines){
    s/TEMPLATE_HOSTNAME/$TEMPLATE_HOSTNAME/g;
    s/TEMPLATE_VCIP/$TEMPLATE_VCIP/g;
    s/TEMPLATE_VCUSER/$TEMPLATE_VCUSER/g;
    s/TEMPLATE_VCPASSWD/$TEMPLATE_VCPASSWD/g;
    s/TEMPLATE_VCCLUSTER/$TEMPLATE_VCCLUSTER/g;
    s/TEMPLATE_CC_IP/$TEMPLATE_CC_IP/g;
    s/TEMPLATE_NCDRIVER/$TEMPLATE_NCDRIVER/g;
    }
    untie @lines;
}

#nova 
update_template($nova_conf);
#cinder
update_template($cinder_conf);
#ceilometer
update_template($ceilometer_conf);



