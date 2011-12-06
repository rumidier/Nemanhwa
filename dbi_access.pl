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

=pod
my %site = (
    naver => {
        name => {
            noblesse => 'http://imgcomic.naver.com/webtoon/25455/thumbnail/title_thumbnail_20100614120245_t125x101.jpg',
            tal      => 'http://imgcomic.naver.com/webtoon/316911/thumbnail/title_thumbnail_20110331153319_t125x101.jpg',
        },
        url  => {
            start_url    => 'http://comic.naver.com/webtoon/list.nhn?titleId=%s',
            webtoon_url  => 'http://comic.naver.com/webtoon/detail.nhn?titleId=%s&no=%s',
        },
    },
    daum => {
        name => {
            thelast => 'http://i1.cartoon.daumcdn.net/svc/image/U03/cartoon/U949E34C4D6B2B9E2D',
            dieter  => 'http://i1.cartoon.daumcdn.net/svc/image/U03/cartoon/U620854C4D5B251707',
        },
        url  => {
            start_url   => 'http://cartoon.media.daum.net/webtoon/view/%s',
            webtoon_url => 'http://cartoon.media.daum.net/webtoon/viewer/%s',
        },
    },
    nate => {
        name => {
            kudu    => 'http://crayondata.cyworld.com/upload/series/31337_m.gif',
        },
        url  => {
            start_url   => 'http://comics.nate.com/webtoon/detail.php?btno=%s',
            webtoon_url => 'http://comics.nate.com/webtoon/detail.php?btno=%s&bsno=%s',
        },
    },
);

    stoo => {
    'http://stoo.asiae.co.kr/cartoon/ctlist.htm?sc1=cartoon&sc2=ing&sc3=%s',
    'http://stoo.asiae.co.kr/cartoon/ctlist.htm?sc1=cartoon&sc2=ing&sc3=57&id=2011120510164573405A
    },

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
=cut

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

#my $test = $site{'naver'}{'name'};
#my @names = @{ $site{'naver'}{'name'} };

for my $site_name ( keys %site ) {
    say "site name : $site_name";

    for my $url_list ( keys $site{$site_name} ) {
        say "    name_list : $url_list";

        if ( $url_list eq 'name' ) {
            for my $toon_name ( keys $site{$site_name}{$url_list} ) {
                say "        toon_name : $toon_name";
                say "              image : $site{$site_name}{$url_list}{$toon_name}";

                my $sth =
                  $dbh->prepare("SELECT COUNT(*) FROM access WHERE name=?");
                $sth->execute($toon_name) or die $!;
                my $count = $sth->fetchrow_arrayref->[0];

                if ($count) {
                    $sth = $dbh->prepare(
                        "UPDATE access SET site=?, `image`=? WHERE name=?");
                    $sth->execute( $site_name,
                        $site{$site_name}{$url_list}{$toon_name}, $toon_name );
                }
                else {
                    $sth = $dbh->prepare(
                        qq/
                            INSERT INTO `access` (
                                `name`,
                                `site`,
                                `image`
                                ) VALUES (?, ?, ?)
                            /
                    );
                    $sth->execute( $toon_name, $site_name,
                        $site{$site_name}{$url_list}{$toon_name} )
                      or die $!;
                }
            }
        }
        elsif ( $url_list eq 'url' ) {

            #start_line table insert
            my $sth =
              $dbh->prepare("SELECT COUNT(*) FROM start_line WHERE site=?");
            $sth->execute($site_name) or die $!;
            my $count = $sth->fetchrow_arrayref->[0];

            if ($count) {
                $sth = $dbh->prepare( "UPDATE start_line SET `start_url`=?, `webtoon_url`=?  WHERE site=?" );
                $sth->execute( $site{$site_name}{$url_list}{'start_url'},
                    $site{$site_name}{$url_list}{'webtoon_url'}, $site_name );
            }
            else {
                $sth = $dbh->prepare( qq/ INSERT INTO `start_line` ( `site`, `start_url`, `webtoon_url`) VALUES (?, ?, ?) / );
                $sth->execute(
                    $site_name,
                    $site{$site_name}{$url_list}{'start_url'},
                    $site{$site_name}{$url_list}{'webtoon_url'}
                ) or die $!;
            }
        }
        else {
            die $!;
        }
    }
}

=pod
for my $site_name ( keys %site ) {
      for my $toon_name (@name) {
          next unless defined( $site{$site_name}{$toon_name} );

          my $sth = $dbh->prepare("SELECT COUNT(*) FROM access WHERE name=?");
          $sth->execute($toon_name) or die $!;
          my $count = $sth->fetchrow_arrayref->[0];

          if ($count) {
              $sth = $dbh->prepare(
                  "UPDATE access SET site=?, `start-url`=? WHERE name=?");
              $sth->execute( $site_name, $site{$site_name}{$toon_name},
                  $toon_name );
          }
          else {
              $sth = $dbh->prepare(
                  qq/
                INSERT INTO `access` (
                    `name`,
                    `site`,
                    `start-url`
                    ) VALUES (?, ?, ?)
                /
              );
              $sth->execute( "$toon_name", $site_name,
                  $site{$site_name}{$toon_name} )
                or die $!;
          }
      }
}


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
