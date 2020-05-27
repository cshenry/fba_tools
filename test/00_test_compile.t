use Test::Most;
use Test::Compile;
use KBaseTestContext;

my $base_dir    = KBaseTestContext->base_dir();
my $test        = Test::Compile->new();

# check all .pm and .pl files compile
$test->all_files_ok( $base_dir );

# check the test files are also OK
my @all_t_files = all_t_files( $test, $base_dir );
for ( @all_t_files ) {
    ok $test->pl_file_compiles( $_ ), $_ . ' compiles';
}

$test->done_testing();

sub all_t_files {
    my ( $test, @dirs ) = @_;

    @dirs = @dirs ? @dirs : ( $base_dir );

    my @t_files;
    for my $file ( $test->_find_files( @dirs ) ) {
        push @t_files, $file if $file =~ /\.t$/;
    }
    return @t_files;
}
