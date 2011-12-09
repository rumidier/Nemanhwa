#!/usr/bin/env perl
use 5.010;
use Dancer qw();
use Dancer::Plugin::Redis;
use File::Basename;
use GD;
 
## 마음대로 골라본 색상 샘플 목록
 
my %sample = (
    gray    => [177, 177, 177],
    black   => [0,   0,   0  ],
    red     => [255, 0,   0  ],
    magenta => [255, 0,   255],
    blue    => [0,   0,   255],
    cyan    => [0,   255, 255],
    green   => [0,   255, 0  ],
    yellow  => [255, 255, 0  ],
    white   => [255, 255, 255],
    ocean   => [125, 148, 183],
    grass   => [125, 183, 133],
    sky     => [125, 183, 174],
    flower  => [183, 125, 181],
    stone   => [183, 174, 125],
    wood    => [183, 125, 125],
);
 
my $page = redis->get("youperl:img:cat.gstar:page");
for my $p (0 .. $page) {
    my @items = redis->lrange("youperl:img:cat.gstar:$p", 0, -1);
    for my $item (@items) {
        my ($img) = glob "public/img/$item.*";
        my $color_name = sampling($img);
 
        redis->sadd("youperl:img:cat.gstar.color:$p:$color_name", $item);
    }
}
 
 
## 가장 가까운 색을 고르자
##
sub sampling {
    my $file = shift;
    return unless -f $file;
 
    my ($hex, $path, $suffix) = fileparse $file, qr/\.[a-z]+/i;
 
    my %dist;
    my $image = new GD::Image($file);
    my $color = new GD::Image(1, 1);
 
    ## 이미지 평균 색상값을 구한다.
    ##
    $color->copyResampled(
        $image,
        (0, 0),   (0, 0),
        (1, 1),   ($image->width, $image->height),
    );
 
    my $index = $color->getPixel(0, 0);
 
    ## 샘플 색상과 각각 비교해본다
    ##
    for my $name (keys %sample) {
        $dist{$name} = rgb_dist( $sample{$name}, [$color->rgb($index)] );
    }
 
    ## 오름차순으로 정렬한다
    ##
    my @sort = sort {
        $dist{$a} <=> $dist{$b}
    } keys %sample;
 
 
    print "$hex:\t $sort[0]\t   ";
    print "$_(", int $dist{$_}, ") " for @sort;
    print "\n";
 
    return $sort[0];
}
 
sub rgb2xyz {
    my ($r, $g, $b) = @_;
    my ($x, $y, $z);
 
    $r = $r / 255;
    $g = $g / 255;
    $b = $b / 255;
 
    for $c ($r, $g, $b) {
        if ($c > 0.04045) {
            $c = ($c + 0.055) / 1.055;
            $c = $c ** 2.4;
        }
        else {
            $c = $c / 12.92;
        }
        $c = $c * 100;
    }
 
    $x = $r * 0.4124 + $g * 0.3576 + $b * 0.1805;
    $y = $r * 0.2126 + $g * 0.7152 + $b * 0.0722;
    $z = $r * 0.0193 + $g * 0.1192 + $b * 0.9505;
 
    return $x, $y, $z;
}
 
sub xyz_dist {
    my ($l, $r) = @_;
    my ($x1, $y1, $z1) = @$l;
    my ($x2, $y2, $z2) = @$r;
    my $t = ($x1 - $x2) ** 2 + ($y1 - $y2) ** 2 + ($z1 - $z2) ** 2;
    return sqrt $t;
}
 
sub rgb_dist {
    my ($l, $r) = @_;
    return xyz_dist [rgb2xyz @$l], [rgb2xyz @$r];
}
