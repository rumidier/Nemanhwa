#!/usr/bin/env perl 

use utf8;
use 5.014;
use strict;
use warnings;
use DBI;
use URI;
use LWP::UserAgent;
use Web::Scraper;
use Data::Dumper;

###
# browser 설정에 대한 이해가 필요
###
my $browser =
  LWP::UserAgent->new( agent => 'Mozilla/5.0'
      . ' (Windows; U; Windows NT 6.1; en-US; rv:1.9.2b1)'
      . ' Gecko/20091014 Firefox/3.6b1 GTB5' );

my $page_scrap = scraper {
    process 'div.episode_list > div.inner_wrap > div.scroll_wrap > ul > li',
      'items[]' => scraper {
        process 'a.img', link  => '@href';
        process 'a.img', title => '@title';
      };    #daum
    process 'table.viewList tr  td.title', 'items[]' => scraper {
        process "a", link => '@href';
    };      #naver
    process 'div.wrap_carousel div.thumbPage div.thumbSet dd',
      'items[]' => scraper {
        process 'a',   link  => '@href';
        process 'img', title => '@alt';
      };    #nate
};

my @select_site = qw(
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
) or die $!;

$dbh->do("set names utf8")
  or die $! . $dbh->errstr . "\n";

#
# 1. naver에 noblesse 의 시작 주소를 가져와
# 전체 list 출력하기
# 2. noblesse 의 처음과 끝을 출력하기

for my $site_name (@select_site) {
    given ($site_name) {
        when ('naver') {
            naver($site_name);
        }
        when ('daum') {
            daum($site_name);
        }
        when ('nate') {
            nate($site_name);
        }
        default {
            say "default";
        }
    }
}

sub get_site_table {
    my $site_name = shift;
    my $sth       = $dbh->prepare(
        "SELECT `id`, `start_url`, `webtoon_url` FROM site WHERE name=?"
    );
    $sth->execute($site_name)
      or die $! . $dbh->errstr . "\n";

    return $sth->fetchrow_array;
}

sub get_webtoon_table {
    my $site_id = shift;
    my $sql     = "SELECT `name`, `code` FROM webtoon WHERE site_id=$site_id";

    return @{ $dbh->selectall_arrayref( $sql, { Slice => {} } ) };
}

sub get_webtoon_id {
    my $webtoon_name = shift;
    my $sql          = "SELECT `id` FROM webtoon WHERE name='$webtoon_name'";

    return @{ $dbh->selectall_arrayref( $sql, { Slice => {} } ) };
}

sub insert_round_table {
    my ( $webtoon_id, @chapter_id_full ) = @_;

    my $chapter = 1;
    for my $chapter_id (@chapter_id_full) {
        my $sth = $dbh->prepare(
            qq/
                INSERT INTO `round` (
                    `webtoon_id`,
                    `chapter`,
                    `chapter_id`
                    ) VALUES (?, ?, ?)
                /
        );
        $sth->execute( $webtoon_id, $chapter, $chapter_id )
          or die $!;

        $chapter++;
    }
}

sub sort_pages {
    my @un_sort_pages = @_;

    my @so_pages = sort {
        my $page_no_a = 0;
        $page_no_a = $1 if $a =~ m/^(\d+)$/;

        my $page_no_b = 0;
        $page_no_b = $1 if $b =~ m/^(\d+)$/;

        $page_no_a <=> $page_no_b;
    } @un_sort_pages;

    return \@so_pages;
}

sub naver {
    my $site_name = shift;
    return 0 unless $site_name eq 'naver';

    my ( $site_id, $start_url, $webtoon_url ) = get_site_table($site_name);
    my @webtoon_col = get_webtoon_table($site_id);

    for my $webtoon_count (@webtoon_col) {
        my $s_url = sprintf( $start_url, $webtoon_count->{'code'} );
        my @links = ();
        my $response;
        $response = $page_scrap->scrape( URI->new($s_url) );

        my @pages = ();
        for my $link ( @{ $response->{items} } ) {
            push @pages, "$link->{link}";
        }

        my @un_pages;
        for (@pages) {
            push @un_pages, ( $_ =~ m/no=(\d+)/ );
        }

        my @so_pages = sort {
            my $page_no_a = 0;
            $page_no_a = $1 if $a =~ m/^(\d+)$/;

            my $page_no_b = 0;
            $page_no_b = $1 if $b =~ m/^(\d+)$/;

            $page_no_a <=> $page_no_b;
        } @un_pages;

        my ($high_round) = ( $so_pages[$#so_pages] =~ m/^(\d+)$/ );
        say "Error parsing" unless $high_round;

        my @full_pages;
        for my $page_count ( 1 .. $high_round ) {
            push @full_pages, $page_count;
        }

        my ($webtoon_table_id) = get_webtoon_id( $webtoon_count->{'name'} );

        my $sth = $dbh->prepare("SELECT COUNT(*) FROM round WHERE webtoon_id=?");
        $sth->execute( $webtoon_table_id->{'id'} )
          or die $!;

        my $count = $sth->fetchrow_arrayref->[0];
        unless ($count) {
            insert_round_table( $webtoon_table_id->{'id'}, @full_pages );
        }
=pod
풀 url 만드는곳
        for my $test ( 1 .. $high_round ) {
            my $print = sprintf( $webtoon_url, $webtoon_count->{'code'}, $test );
            say "$test : $print";
        }
=cut
    }
}

sub daum {
    my $site_name = shift;
    return 0 unless $site_name eq 'daum';

    my ( $site_id, $start_url, $webtoon_url ) = get_site_table($site_name);
    my @webtoon_col = get_webtoon_table($site_id);

    for my $webtoon_count (@webtoon_col) {
        my $s_url = sprintf( "$start_url", $webtoon_count->{'code'} );
        my @links = ();
        my $response;
        $response = $page_scrap->scrape( URI->new($s_url) );

        my @pages = ();
        for my $link ( @{ $response->{items} } ) {
            push @pages, "$link->{link}";
        }

        my @un_pages;
        for (@pages) {
            push @un_pages, ( $_ =~ m/viewer\/(\d+)$/ );
        }

        my @so_pages = sort {
            my $page_no_a = 0;
            $page_no_a = $1 if $a =~ m/^(\d+)$/;

            my $page_no_b = 0;
            $page_no_b = $1 if $b =~ m/^(\d+)$/;

            $page_no_a <=> $page_no_b;
        } @un_pages;

        my ($high_round) = ( $so_pages[$#so_pages] =~ m/^(\d+)$/ );
        say "Error" unless defined $high_round;

        my @webtoon_table_id = get_webtoon_id( $webtoon_count->{'name'} );

        my $sth = $dbh->prepare("SELECT COUNT(*) FROM round WHERE webtoon_id=?");
        $sth->execute( $webtoon_table_id[0]->{'id'} )
          or die $!;

        my $count = $sth->fetchrow_arrayref->[0];
        unless ($count) {
            insert_round_table( $webtoon_table_id[0]->{'id'}, @so_pages );
        }

        sleep 5;
    }
}

sub nate {
    my $site_name = shift;
    return 0 unless $site_name eq 'nate';

    my ( $site_id, $start_url, $webtoon_url ) = get_site_table($site_name);
    my @webtoon_col = get_webtoon_table($site_id);

    for my $webtoon_count (@webtoon_col) {
        my $s_url    = sprintf( "$start_url", $webtoon_count->{'code'} );
        my @links    = ();
        my $response = $page_scrap->scrape( URI->new($s_url) );
        my @pages    = ();

        for my $link ( @{ $response->{items} } ) {
            push @pages, "$link->{link}";
        }

        my @un_pages;
        for (@pages) {
            push @un_pages, ( $_ =~ m/bsno=(\d+)$/ );
        }
        my @so_pages = sort_pages (@un_pages);

        my ($high_round) = ( $so_pages[$#so_pages] =~ m/^(\d+)$/ );

        my @webtoon_table_id = get_webtoon_id( $webtoon_count->{'name'} );
        my $sth = $dbh->prepare("SELECT COUNT(*) FROM round WHERE webtoon_id=?");
        $sth->execute( $webtoon_table_id[0]->{'id'} )
          or die $!;

        my $count = $sth->fetchrow_arrayref->[0];
        unless ($count) {
            insert_round_table( $webtoon_table_id[0]->{'id'}, @so_pages );
        }

        sleep 5;
    }
}

