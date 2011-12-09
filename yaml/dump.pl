#!/usr/bin/env perl

use utf8;
use 5.014;
use strict;
use warnings;
use Data::Dumper;
use YAML::Tiny;

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
print Dumper \%site;

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

my %dummy = (
    dummy_a => [
        'aaa',
        'bbb',
        'ccc',
    ],
    dummy_b => [
        'aaa',
        {
            abc => '111',
            def => '234',
        },
        [
            1023,
            523,
        ],
        'ccc',
    ]
);

my $yaml = YAML::Tiny->new;
$yaml->[0] = {
    site => \%site,
    webtoon => \%webtoon,
    dummy => \%dummy,
};

$yaml->write( 'just-test.yml' );
