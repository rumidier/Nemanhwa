#!/usr/bin/env perl 

use 5.014;
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
my ( $start_page_num, $last_page_num ) = @ARGV;
$start_page_num ||= 1;
$last_page_num  ||= 3;
 
# page scraper
my $page_scrap = scraper {
    process "a", 'link[]' => '@href';
};
 
# bbs scraper
my $bbs_scrap = scraper {
    process 'img', 'imglink[]' => '@src';
};
 
for my $current_page_num ( $start_page_num .. $last_page_num ) {
    print "current page : $current_page_num" . "\n";
    my $g_name = sprintf(
        'http://gall.dcinside.com/list.php?id=racinggirl&page=%s',
        $current_page_num,
    );
    my $links = get_image_links($g_name);
 
    # delete Notice :D

    print "-- After\n";
    print Dumper \$links;
    if ( $current_page_num == 1 ) {
        shift( @{$links} ) for ( 1 .. 6 );
    }
    print "-- Before\n";
    print Dumper \$links;
# download($links);
    sleep 5;
}
 
sub get_image_links {
    my $url = shift;
    my @links;
    my $response;
    eval { $response = $page_scrap->scrape( URI->new($url) ); };
    warn $@ if $@;
 
    for my $link ( @{ $response->{link} } ) {
        next unless $link =~ /bbs=$/;
        push @links, $link;
    }
 
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
