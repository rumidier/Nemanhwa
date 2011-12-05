#!/usr/bin/env perl 

use 5.014;
use strict;
use warnings;
use WWW::Mechanize;

my $id = 'rumidier';
my $passwd = 'gksdud08';
my $replay = 'Check! :0';
chomp($replay);

my $url = "http://nid.naver.com/nidlogin.login";
my $mech = WWW::Mechanize->new();

$mech->get($url);
my $res = $mech->submit_form(
    form_name => 'frmNIDLogin',
    fields    => {
        id => 'rumidier',
        pw => 'gksdud08'
    },
);

my $check_url = 'http://cafe.naver.com/cstudyjava?20111129093526';
$mech->get($check_url);
$mech->field('content','Check! :)');
$mech->submit();
