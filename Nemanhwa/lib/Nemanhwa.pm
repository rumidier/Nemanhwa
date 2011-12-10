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

get '/category' => sub {
    my @daum_full;
    for my $site_name ( keys $site ) {
        debug "site_name : $site_name\n";
        next if "$site_name" ne 'daum';

        my $sth = $dbh->prepare( "SELECT `id`, `start_url`, `webtoon_url` FROM site WHERE name=?");
        $sth->execute($site_name)
            or die $! . $dbh->errstr . "\n";
        my ( $site_id, $strat_url, $webtoon_url ) = $sth->fetchrow_array;
       debug "---|| site_id : $site_id : start_url : $strat_url : webtoon_url : $webtoon_url\n";



       my $sql =  "SELECT `id`, `code`, `name` FROM webtoon WHERE site_id='$site_id'";
       my @test = @{ $dbh->selectall_arrayref( $sql, { Slice => {} } ) };

       for my $webtoon_list ( @test ) {
           $sql =  "SELECT `chapter`, `chapter_id` FROM round WHERE webtoon_id='$webtoon_list->{'id'}'";
           my @test2 = @{ $dbh->selectall_arrayref( $sql, { Slice => {} } ) };

           for my $test3 (@test2) {
               my $print = sprintf( $webtoon_url, $test3->{'chapter_id'});
               push @daum_full, $print;
           }
       }

    }

    template 'test', { test => \@daum_full };
};

true;
