#!/usr/bin/perl -w
while(<>){
    chomp;
    if(/\d+/){
        print "Matched: |$` <$&> $'|\n";
    }else{
        print "No match: |$_|\n";
    }
}