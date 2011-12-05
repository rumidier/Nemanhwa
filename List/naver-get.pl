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

my $browser =
  LWP::UserAgent->new( agent => 'Mozilla/5.0'
      . ' (Windows; U; Windows NT 6.1; en-US; rv:1.9.2b1)'
      . ' Gecko/20091014 Firefox/3.6b1 GTB5' );
my $file_num = 0;

# page scraper
my $page_scrap = scraper {
    process "a", 'link[]' => '@href';
};

# bbs scraper
my $bbs_scrap = scraper {
    process 'img', 'imglink[]' => '@src';
};

my $page_count = 1;

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
) or die $!;

$dbh->do("set names utf8")
    or die $! . $dbh->errstr . "\n";

#
# 1. naver에 noblesse 의 시작 주소를 가져와
# 전체 list 출력하기
# 2. noblesse 의 처음과 끝을 출력하기
for my $site_name ( @site_name ) {
    naver( $site_name )
};

sub naver {
    my $site_name = shift;
    return 0 unless $site_name eq 'naver';

    for my $toon_name ( @name ) {
        my $sth = $dbh->prepare("SELECT `start-url` FROM access WHERE name=? and site=?");

        $sth->execute( $toon_name, $site_name)
            or die $! . $dbh->errstr . "\n";
        my $row = $sth->fetchrow_array;

        next unless defined($row);

        my $start_url = sprintf($row);

        my $word = $1 if $start_url =~ m/(\d+)$/g;
        my @links = ();
        my $response;
        $response = $page_scrap->scrape( URI->new($start_url) );

        my @pages = ();
        next unless defined $word;

        push @pages, $start_url;
        for my $link ( @{ $response->{link} } ) {
            next unless $link =~ /$word&page/;
            push @pages, "$link";
        }

        my %cont;
        for my $item (@pages) {
            $cont{$item}++;
        }

        my @un_pages = sort keys %cont;
        my @so_pages = sort {
            my $page_no_a = 0;
            $page_no_a = $1 if $a =~ m/page=(\d+)/;

            my $page_no_b = 0;
            $page_no_b = $1 if $b =~ m/page=(\d+)/;
            
            $page_no_a <=> $page_no_b;
        } @un_pages;

        print Dumper \@so_pages;
        get_links($word, @so_pages);
        sleep 5;
#say $row;

=pod
            my $sth = $dbh->prepare("SELECT name FROM access WHERE site=?");
            $sth->execute( $site_name );
            my @row = $sth->fetchrow_array;
            say "@row";
=cut
    }
    sleep 5;
};

sub get_links {
    my ( $word, @url_list ) = @_;
    my @links = ();
    my $last_round;
    my $first_round;

    sleep 2;
    for my $url (@url_list) {
        my $response;
        eval { $response = $page_scrap->scrape( URI->new($url) ); };
        warn $@ if $@;

        for my $link ( @{ $response->{link} } ) {
      next unless $link =~ /$word&no=(\d+)&weekday/;

            $first_round = $link unless defined($last_round);
            $last_round  = $link unless defined($last_round);

            given ($link) {
                when (@links) {
                }
                default {
                    push @links, "$link";
                    $last_round  = $link if $last_round le $link;
                    $first_round = $link if $first_round ge $link;
                }
            }
        }

        sleep 3;
    }
    print Dumper \@links;

#push @links, "$last_round";
#push @links, "$first_round";
    return \@links;


};

=pod
for my $site_name ( @site_name ) {
    next if $site_name ne 'naver';
    for my $toon_name ( @name ) {
        my $sth = $dbh->prepare("SELECT COUNT(*) FROM access WHERE name=?");
        $sth->execute($toon_name) or die $!;
        my $count = $sth->fetchrow_arrayref->[0];

        if ($count) {
            $sth = $dbh->prepare("SELECT name FROM access WHERE site=?");
            $sth->execute( $site_name );
            my @row = $sth->fetchrow_array;
            say "@row";
        }
        else {
            say "kkkkkkk";
        }
    }
};

while (1) {
#for my $current_page_num ( $start_page_num .. $last_page_num ) {
    print "current page : $page_count" . "\n";
    my $g_name = sprintf(
        'http://comic.naver.com/webtoon/list.nhn?titleId=25455&weekday=tue&page=%s',
        $current_page_num,
    );
    my $g_name = sprintf(
            'http://comics.nate.com/webtoon/detail.php?btno=31337&category'
    );
    my $links = get_image_links($g_name);

    my $first_round;
    my $last_round;

    $first_round = pop(@{ $links });
    $last_round = pop(@{ $links });
 
#download($links);
    sleep 5;
    $page_count++;
    last if ($page_count ge '1');
}
=cut

sub get_image_links {
    my $url   = shift;
    my @links = ();
    my $response;
    eval { $response = $page_scrap->scrape( URI->new($url) ); };
    warn $@ if $@;

    my $last_round;
    my $first_round;
    for my $link ( @{ $response->{link} } ) {
        next unless $link =~ /31337&bsno/;

        $first_round = $link unless defined($last_round);
        $last_round  = $link unless defined($last_round);

        given ($link) {
            when (@links) {
            }
            default {
                push @links, "$link";
                $last_round  = $link if $last_round le $link;
                $first_round = $link if $first_round ge $link;
            }
        }
    }

    push @links, "$last_round";
    push @links, "$first_round";
    return \@links;
}
