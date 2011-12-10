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
use YAML::Tiny;

###
# start_line table 입력정보
###

# 아..아름 답지 않아...
my $yaml      = YAML::Tiny->read( 'dbi.yml' );
my $database  = $yaml->[0]->{'db_config'}{'database'};
my $host      = $yaml->[0]->{'db_config'}{'host'};
my $db_user   = $yaml->[0]->{'db_config'}{'db_user'};
my $db_passwd = $yaml->[0]->{'db_config'}{'db_passwd'};
my $webtoon   = $yaml->[0]->{'webtoon'};
my $site      = $yaml->[0]->{'site'};

my $dbh = DBI->connect(
    "DBI:mysql:database=$database;host=$host",
    "$db_user",
    "$db_passwd",
    {
        RaiseError => 1,
        AutoCommit => 1,
    },
);
$dbh->do("set names utf8");

for my $site_name ( keys $site ) {
    for my $url_list ( keys $site->{$site_name} ) {
        my $sth = $dbh->prepare("SELECT COUNT(*) FROM site WHERE name=?");
        $sth->execute($site_name) or die $!;

        my $count = $sth->fetchrow_arrayref->[0];
        if ($count) {
            $sth = $dbh->prepare("UPDATE site SET $url_list=? WHERE name=?");
            $sth->execute( $site->{$site_name}{$url_list}, $site_name )
                or die $!;
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
            $sth->execute( $site_name, $site->{$site_name}{$url_list} )
              or die $!;
        }
    }
}

for my $site_name ( keys $webtoon ) {
    my $sth = $dbh->prepare("SELECT COUNT(*) FROM site WHERE name=?");
    $sth->execute($site_name) or die $!;

    my $count = $sth->fetchrow_arrayref->[0];
    say "$site_name is not match" next unless $count;

    my @ids = @{ $dbh->selectall_arrayref("SELECT id FROM site WHERE name = '$site_name'", { Slice => {} }) };
    my $site_id = $ids[0]->{'id'};
    say "$site_id is not match" next unless $site_id;

    for my $webtoon_name ( keys $webtoon->{$site_name} ) {
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

        for my $code_image ( keys $webtoon->{$site_name}{$webtoon_name} ) {
            $sth = $dbh->prepare("UPDATE webtoon SET $code_image=? WHERE name=?");
            $sth->execute( $webtoon->{$site_name}{$webtoon_name}{$code_image}, $webtoon_name );
        }
    }
}
