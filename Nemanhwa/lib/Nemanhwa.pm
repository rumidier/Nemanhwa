package Nemanhwa;

use utf8;
use 5.014;
use Dancer ':syntax';
use DBI;
use Data::Dumper;
use YAML::Tiny;

our $VERSION = '0.1';

my $yaml      = YAML::Tiny->read( 'dbi.yml' );
my $database  = $yaml->[0]->{'db_config'}{'database'};
my $host      = $yaml->[0]->{'db_config'}{'host'};
my $db_user   = $yaml->[0]->{'db_config'}{'db_user'};
my $db_passwd = $yaml->[0]->{'db_config'}{'db_passwd'};
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

get '/' => sub {
    template 'index';
};

sub s_printf {
    my ( $webtoon_url, $webtoon_code, $webtoon_name, $webtoon_main_image ) = @_;

    my $prin = sprintf( "<img src=%s />$webtoon_name: <a href=$webtoon_url>첫화보기</a>", $webtoon_main_image, $webtoon_code, 1, );

    return $prin;
}

get '/daum' => sub {
    template 'daum';
};
get '/category' => sub {
    my @daum  = ();
    my @naver = ();
    my @nate  = ();
    for my $site_name ( keys $site ) {
        my $sth = $dbh->prepare( "SELECT `id`, `start_url`, `webtoon_url` FROM site WHERE name=?");
        $sth->execute($site_name)
            or die $! . $dbh->errstr . "\n";
        my ( $site_id, $strat_url, $webtoon_url ) = $sth->fetchrow_array;
        my $sql           = "SELECT `id`, `code`, `name`, `image` FROM webtoon WHERE site_id='$site_id'";
        my @webtoon_lines = @{ $dbh->selectall_arrayref( $sql, { Slice => {} } ) };

        if ( "$site_name" eq 'daum' ) {
            for my $webtoon_line ( @webtoon_lines ) {
                my $webtoon_code       = "$webtoon_line->{'code'}";
                my $webtoon_name       = "$webtoon_line->{'name'}";
                my $webtoon_main_image = "$webtoon_line->{'image'}";

                my $print = sprintf(
                        "$webtoon_line->{'name'}: <img src=%s /><a href=$webtoon_url>첫화보기</a>",
                        $webtoon_line->{'image'},
                        $webtoon_line->{'code'}
                        );
                push @daum, $print;
            };
        }
        else {
            for my $webtoon_line ( @webtoon_lines ) {
                my $webtoon_code       = "$webtoon_line->{'code'}";
                my $webtoon_name       = "$webtoon_line->{'name'}";
                my $webtoon_main_image = "$webtoon_line->{'image'}";

                if ( "$site_name" eq 'naver' ) {
                    my $print = s_printf( $webtoon_url, $webtoon_code, $webtoon_name, $webtoon_main_image );
                    push @naver, $print;
                }
                elsif ( "$site_name" eq 'nate' ) {
                    my $print = s_printf( $webtoon_url, $webtoon_code, $webtoon_name, $webtoon_main_image );
                    push @nate, $print;
                }

            };
        }
    }

    template 'test', { daum => \@daum, naver => \@naver, nate => \@nate };
};


=pod
get '/category' => sub {
    my @daum_full;
    my @naver_full;
    my $tt;
    for my $site_name ( keys $site ) {
        debug "site_name : $site_name\n";

        my $sth = $dbh->prepare( "SELECT `id`, `start_url`, `webtoon_url` FROM site WHERE name=?");
        $sth->execute($site_name)
            or die $! . $dbh->errstr . "\n";
        my ( $site_id, $strat_url, $webtoon_url ) = $sth->fetchrow_array;
       debug "---|| site_id : $site_id : start_url : $strat_url : webtoon_url : $webtoon_url\n";



       my $sql =  "SELECT `id`, `code`, `name` FROM webtoon WHERE site_id='$site_id'";
       my @test = @{ $dbh->selectall_arrayref( $sql, { Slice => {} } ) };

       if ( "$site_name" eq 'daum' ) {
           for my $webtoon_list ( @test ) {
               $tt = "$webtoon_list->{'name'}";
               $sql =  "SELECT `chapter`, `chapter_id` FROM round WHERE webtoon_id='$webtoon_list->{'id'}'";
               my @test2 = @{ $dbh->selectall_arrayref( $sql, { Slice => {} } ) };

               for my $test3 (@test2) {
                   my $print = sprintf( $webtoon_url, $test3->{'chapter_id'});
#                   push @daum_full, $print;
               }
           }
       }
       else {
           for my $webtoon_list ( @test ) {
               $sql =  "SELECT `chapter`, `chapter_id` FROM round WHERE webtoon_id='$webtoon_list->{'id'}'";
               my @test2 = @{ $dbh->selectall_arrayref( $sql, { Slice => {} } ) };

               for my $test3 (@test2) {
                   my $print = sprintf( $webtoon_url, $webtoon_list->{'code'}, $test3->{'chapter_id'} );
                   push @naver_full, $print;
               }
           }
       }

    }

    template 'test', { daum => \@daum_full, naver => \@naver_full };
};
=cut

true;
