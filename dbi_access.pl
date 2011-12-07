#!/usr/bin/env perl

use utf8;
use 5.014;
use strict;
use warnings;
use DBI;
use Text::CSV::Encoded;
use Text::CSV_XS;
use Data::Dumper;
use File::Basename;

###
# start_line table 입력정보
###

my %site = (
    naver => {
        start_url   => 'http://comic.naver.com/webtoon/list.nhn?titleId=%s',
        webtoon_url => 'http://comic.naver.com/webtoon/detail.nhn?titleId=%s&no=%s',
    },
    daum => {
        start_url   => 'http://cartoon.media.daum.net/webtoon/view/%s',
        webtoon_url => 'http://cartoon.media.daum.net/webtoon/viewer/%s',
    },
    nate => {
        start_url   => 'http://comics.nate.com/webtoon/detail.php?btno=%s',
        webtoon_url => 'http://comics.nate.com/webtoon/detail.php?btno=%s&bsno=%s',
    },
);

my %webtoon = (
    naver => {
        noblesse => {
            code  => '25455',
            image => 'http://imgcomic.naver.com/webtoon/25455/thumbnail/title_thumbnail_20100614120245_t125x101.jpg',
        },
        tal      => {
            code  => '316911',
            image => 'http://imgcomic.naver.com/webtoon/316911/thumbnail/title_thumbnail_20110331153319_t125x101.jpg',
        }
    },
    daum => {
        last => {
            code  => 'thelast',
            image => 'http://i1.cartoon.daumcdn.net/svc/image/U03/cartoon/U949E34C4D6B2B9E2D',
        },
        dieter => {
            code  => 'dieter',
            image => 'http://i1.cartoon.daumcdn.net/svc/image/U03/cartoon/U620854C4D5B251707',
        },
      },
    nate => {
        kudu => {
            code  => '31337',
            image => 'http://crayondata.cyworld.com/upload/series/31337_m.gif',
        },
      },
);

my $dbh = DBI->connect(
    "DBI:mysql:database=webtoon;host=localhost",
    "root",
    "rumidier",
    {
        RaiseError => 1,
        AutoCommit => 1,
    },
);
$dbh->do("set names utf8");

for my $site_name ( keys %webtoon ) {
    say "site_name : $site_name";
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM site WHERE name=?");
    $sth->execute($site_name) or die $!;

    my $count = $sth->fetchrow_arrayref->[0];
    next unless $count;

    my @ids = @{ $dbh->selectall_arrayref("SELECT id FROM site WHERE name = '$site_name'", { Slice => {} }) };
    my $site_id = $ids[0]->{'id'};
    say "site_id     : $site_id";
    
    for my $webtoon_name ( keys $webtoon{$site_name} ) {
        say "    webtoon_name : $webtoon_name";
        for my $co_im ( keys $webtoon{$site_name}{$webtoon_name} ) {
            say "        co_im : $co_im";
        }
    }
}

=pod
for my $site_name ( keys %site ) {
    for my $url_list ( keys $site{$site_name} ) {
        my $sth = $dbh->prepare("SELECT COUNT(*) FROM site WHERE name=?");
        $sth->execute($site_name) or die $!;

        my $count = $sth->fetchrow_arrayref->[0];
        if ($count) {
            $sth = $dbh->prepare("UPDATE site SET $url_list=? WHERE name=?");
            $sth->execute( $site{$site_name}{$url_list}, $site_name );
        }
        else {
            $sth = $dbh->prepare(
                qq/
                    INSERT INTO `site` (
                        `name`,
                        `start_url`
                        ) VALUES (?, ?)
                    /
            );
            $sth->execute( $site_name, $site{$site_name}{$url_list} )
              or die $!;
        }
    }
}
=cut
