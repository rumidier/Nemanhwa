use YAML::Tiny;
 
# Create a YAML file
my $yaml = YAML::Tiny->new;
 
# Open the config
$yaml = YAML::Tiny->read( 'file.yml' );
 
# Reading properties
my $root = $yaml->[0]->{rootproperty};
my $one  = $yaml->[0]->{section}->{one};
my $Foo  = $yaml->[0]->{section}->{Foo};

print "$root\n";
print "$one\n";
print "$Foo\n";

use Data::Dumper;

print Dumper($yaml);
