#!/usr/bin/env perl 

use 5.014;
use utf8;
use Encode;
use strict;
use warnings;
use URI;
use LWP::UserAgent;
use Web::Scraper;
use Data::Dumper;
 
my $browser = LWP::UserAgent->new( agent =>
     'Mozilla/5.0'
    .' (Windows; U; Windows NT 6.1; en-US; rv:1.9.2b1)'
    .' Gecko/20091014 Firefox/3.6b1 GTB5'
);
my $file_num = 0;
=pod
my ( $start_page_num, $last_page_num ) = @ARGV;
$start_page_num ||= 1;
$last_page_num  ||= 1;
=cut
 
# page scraper
my $page_scrap = scraper {
    process 'div.episode_list > div.inner_wrap > div.scroll_wrap > ul > li', 'items[]' => scraper {
        process 'a.img', link => '@href';
        process 'a.img', title => '@title';
    };
#    process "a", 'link[]' => '@href';
#    process "a", 'link[]' => '@href';
};
 
# bbs scraper
my $bbs_scrap = scraper {
    process 'img', 'imglink[]' => '@src';
};
 
my $page_count = 1;
while (1) {
#for my $current_page_num ( $start_page_num .. $last_page_num ) {
    print "current page : $page_count" . "\n";
=pod
    my $g_name = sprintf(
        'http://comic.naver.com/webtoon/list.nhn?titleId=25455&weekday=tue&page=%s',
        $current_page_num,
    );
=cut
    my $g_name = sprintf(
#'http://cartoon.media.daum.net/webtoon/viewer/10362'
'http://cartoon.media.daum.net/webtoon/viewer/10479'
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
 
sub get_image_links {
    my $url = shift;
    my @links = ();
    my $response;
    eval { $response = $page_scrap->scrape( URI->new($url) ); };
    warn $@ if $@;

    my $last_round;
    my $first_round;
    for my $item ( @{ $response->{items} } ) {
        my $str = encode("utf8", $item->{link});
        say "DEBUG: [$str]";

#        next unless $link =~ /viewer\/(\d+)$/;

#                push @links, "$link";
=pod
        $first_round = $link unless defined($first_round);
        $last_round = $link unless defined($last_round);

        given ($link) {
            when (@links){
            }
            default {
                $last_round = $link if $last_round le $link;  
                $first_round = $link if $first_round ge $link;  
            }
        }
=cut
    }
 
#   push @links, "$last_round";
#    push @links, "$first_round";
my @so_pages = sort { 
            my $page_no_a = 0; 
            $page_no_a = $1 if $a =~ m/viewer\/(\d+)$/;

            my $page_no_b = 0; 
            $page_no_b = $1 if $b =~ m/viewer\/(\d+)$/;

            $page_no_a <=> $page_no_b; 
        } @links; 

    say Dumper \@so_pages;
    return \@links;
}

=pod 
sub download {
    my $links = shift;
 
    for my $article_link ( @{$links} ) {
        my $response;
        eval { $response = $bbs_scrap->scrape( URI->new($article_link) ); };
        if ($@) {
            warn $@;
            next;
        }
        for my $img_link ( @{ $response->{imglink} } ) {
            if ( $img_link =~ m|http://dcimg| ) {
                print $img_link . "\n";
 
                my $ua = LWP::UserAgent->new();
                my $res;
                eval { $res = $ua->get($img_link); };
                if ($@) {
                    warn $@;
                    next;
                }
 
                my $file = sprintf 'img_%04d.jpg', ++$file_num;
                open my $fh, ">", $file;
                binmode $fh;
                print $fh $res->content;
                close $fh;
            }
        }
    }
}
=cut
