#!/usr/bin/perl
use strict;
use warnings;

my $file = $ARGV[0];
open my $fh, "<", $file or die $!;
binmode($fh);

my $buf;
my $data;

for(my $addr = 0; $addr < 0x1000; $addr++){
    if($addr % 4 == 0){
	printf "    ";
    }
    if(sysread($fh, $buf, 1)){
	$data = unpack("C", $buf);
    } else {
	$data = 0;
    }
    printf("rom['h%03X]=8'h%02X;", $addr, $data);
    if($addr % 4 == 3){
	printf "\n";
    } else {
	printf " ";
    }
}

close $fh;
    
