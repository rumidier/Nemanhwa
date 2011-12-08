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
        start_url   => 'http://cartoon.media.daum.net/webtoon/viewer/%s',
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
            code  => '10479',
            image => 'http://i1.cartoon.daumcdn.net/svc/image/U03/cartoon/U949E34C4D6B2B9E2D',
        },
        dieter => {
            code  => '10362',
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

for my $site_name ( keys %webtoon ) {
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM site WHERE name=?");
    $sth->execute($site_name) or die $!;

    my $count = $sth->fetchrow_arrayref->[0];
    next unless $count;

    my @ids = @{ $dbh->selectall_arrayref("SELECT id FROM site WHERE name = '$site_name'", { Slice => {} }) };
    my $site_id = $ids[0]->{'id'};
####
# site_id 가져 왔으니까 포탈별로 site_id 넣고
# site_name 키로 %webtoon에서 web_name키로 찾아서 name 넣고
# name 키로 code랑 image값 너면 오케이
####
    for my $webtoon_name ( keys $webtoon{$site_name} ) {
        my $sth = $dbh->prepare("SELECT COUNT(*) FROM site WHERE id=? and name=?");
        $sth->execute($site_id, $site_name) or die $!;

        my $count = $sth->fetchrow_arrayref->[0];
        next unless $count; #site에 등록 정보가 없으면 스킵

        $sth = $dbh->prepare("SELECT COUNT(*) FROM webtoon WHERE site_id=? and name=?");
        $sth->execute($site_id, $webtoon_name) or die $!;

        $count = $sth->fetchrow_arrayref->[0];
        unless ($count) {
            $sth = $dbh->prepare(
                    qq/
                    INSERT INTO `webtoon` (
                        `site_id`,
                        `name`
                        ) VALUES (?, ?)

                    /
                    );
            $sth->execute( $site_id, $webtoon_name )
                or die $!;
        }

        for my $code_image ( keys $webtoon{$site_name}{$webtoon_name} ) {
            $sth = $dbh->prepare("UPDATE webtoon SET $code_image=? WHERE name=?");
            $sth->execute( $webtoon{$site_name}{$webtoon_name}{$code_image}, $webtoon_name );
        }
    }
}
