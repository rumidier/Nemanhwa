#!/usr/bin/env perl 

use utf8;
use 5.014;
use strict;
use warnings;

use Dancer qw();
use Dancer::Plugin::Redis;
use Digest::MD5 qw(md5_hex);
use GD::Thumbnail;
use File::Basename;
use Data::Dumper;
use LWP::Simple;
 
## 시작 전 데이터베이스 항목 초기화
redis->setnx("youperl:img:cat.gstar:page", 0);
 
## 긁을 페이지 목록을 구하는 구하는 정규표현식과
## 각 페이지에서 이미지를 긁을 정규표현식
my $grep_srclist = qr|<a href="([^"]+)".{1,30}지스타 2011 부스걸 사진 보기|si;
my $grep_imglist = qr|http://p.playforum.net/[^"]+|si;
 
## 일단 첫번째 페이지를 가져와요!
my $first_page = 'http://www.playforum.net/www/newsDirectory/-/id/1047955';
my $src_list = get $first_page;
 
## 페이지 목록을 긁어요!
my @urls = $src_list =~ m/$grep_srclist/g;
my @imgs;
 
## 각 페이지를 순회하면서 이미지 목록을 긁어요!
for my $url ($first_page, @urls) {
    say " <- $url";
    my $src_imgs = get $url;
    push @imgs, $src_imgs =~ m/$grep_imglist/g;
}

## 각 이미지를 처리합니다.
for my $img (@imgs) {
    my ($name, $path, $suffix) = fileparse $img, qr/\.[a-z]+/i;
    my $hex = md5_hex "youperl_$path$name";
    my $fn = "public/img/$hex$suffix";
    my $thumb = "public/img/thumb/$hex$suffix";
    my $i;
 
    ## 유일한 파일명을 구해요.
    while (-e $fn) {
        ++$i;
        $fn = sprintf "public/img/${hex}_%d$suffix", $i;
        $thumb = sprintf "public/img/thumb/${hex}_%d$suffix", $i;
    }
    $hex = "${hex}_$i" if defined $i;
 
    ## 이미지를 저장하구요.
    say " -> $fn";
    getstore $img, $fn unless -e $fn;
 
    ## 작은 파일은 필요 없습니다.
    if (-s $fn < 1024 * 8) {
        say " xx $fn";
        unlink $fn;
        next;
    }
 
    ## 썸네일도 생성합시다.
    say " -> $thumb";
    my $t = GD::Thumbnail->new;
    my $raw = $t->create($fn, 140, 0);
    open my $fh, '>', $thumb or die;
    binmode $fh;
    print $fh $raw;
 
    say " -o $fn";
    ## 데이터베이스에 400개씩 기록합니다. (이 부분은 대체 뭐지?)
    my $page = redis->get("youperl:img:cat.gstar:page");
    my $size = redis->llen("youperl:img:cat.gstar:$page");
    if ($size >= 400) {
        $page = redis->incr("youperl:img:cat.gstar:page");
    }
    redis->lpush("youperl:img:cat.gstar:$page", $hex);
}
