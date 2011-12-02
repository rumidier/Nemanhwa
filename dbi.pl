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

my %site = (
    naver => {
        "noblesse" =>
          'http://comic.naver.com/webtoon/list.nhn?titleId=25455&page=1',
        "tal" =>
          'http://comic.naver.com/webtoon/list.nhn?titleId=316911&page=1',
        "doctor" =>
          'http://comic.naver.com/webtoon/list.nhn?titleId=293523&page=1',
    },
    daum => {
        "thelast" => 'http://cartoon.media.daum.net/webtoon/view/thelast#1',
        "dieter"  => 'http://cartoon.media.daum.net/webtoon/view/dieter#1',
        "taoistland" =>
          'http://cartoon.media.daum.net/webtoon/view/taoistland#1',
    },
    nate => {
        "kudu" =>
          'http://comics.nate.com/webtoon/detail.php?btno=31337&category=1',
        "ant" =>
          'http://comics.nate.com/webtoon/detail.php?btno=31852&category=1',
    },
    stoo => {
        "king" =>
'http://stoo.asiae.co.kr/cartoon/ctlist.htm?sc1=cartoon&sc2=ing&sc3=57',
    },
);

my @name = qw(
  noblesse tal doctor
  thelast dieter taoistland
  kudu ant
  king
);

my @site_name = qw(
    naver
    daum
    nate
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
    for my $toon_name (@name) {
        next unless defined( $site{$site_name}{$toon_name} );

        my $sth = $dbh->prepare("SELECT COUNT(*) FROM access WHERE name=?");
        $sth->execute($toon_name) or die $!;
        my $count = $sth->fetchrow_arrayref->[0];

        if ($count) {
            $sth =
              $dbh->prepare("UPDATE access SET site=?, start=? WHERE name=?");
            $sth->execute( $site_name, $site{$site_name}{$toon_name},
                $toon_name );
        }
        else {
            $sth = $dbh->prepare(
                qq/
                INSERT INTO `access` (
                    `name`,
                    `site`,
                    `start`
                    ) VALUES (?, ?, ?)
                /
            );
            $sth->execute( "$toon_name", $site_name,
                $site{$site_name}{$toon_name} )
              or die $!;
        }
    }
}

=pod

while ( my $row = $csv->getline_hr($fh) ) {
    given ($target_table) {
        when (@type_a_pattern) {
            say "[DEBUG]: $target_header_file $target_data_file";

            foreach my $key (@$header) {
                next if $key eq 'serial';
                if ($count) {
                    $sth = $dbh->prepare(
                        "UPDATE $table SET $column=? WHERE serial=?");
                    $sth->execute( $row->{$key}, $serial ) or die $!;
                }
                else {
                    $sth = $dbh->prepare(
                        qq/
                                INSERT INTO `$table` (
                                    `serial`,
                                    `lab_id`,
                                    `$column`,
                                    `localid`,
                                    `status`
                                    ) VALUES ( ?, ?, ?, ?, ? )
                                /
                    );
                    $sth->execute( $serial, $lab_id, $row->{$key}, $localid,
                        $status )
                      or die $!;
                }
            }
        }
    }
}
=cut
