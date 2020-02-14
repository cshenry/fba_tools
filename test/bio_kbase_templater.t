use Test::Most;
use Test::Output;
use Path::Tiny;
use Data::Dumper::Concise;
use feature qw( say );

require_ok 'Bio::KBase::Templater';

# get the current test/data directory path
# TODO: more robust way to find directory
my $cwd      = Path::Tiny->cwd;
my $data_dir = $cwd->child( 'test/data' );

subtest 'populate_template' => sub {

    my $tests = [
    {   args    => [ 'does/not/exist' ],
        error   => qr/template rendering error: file error/i,
        desc    => 'template not found',
    },
    {
        args    => [
            $data_dir->child( 'test.tt' ),
            {},
            'a random string'
        ],
        error   => qr/template rendering error: not a glob reference/i,
        desc    => 'invalid output file',
    } ];

    for ( @$tests ) {
        throws_ok {
            Bio::KBase::Templater::render_template( @{ $_->{ args } } );
        } $_->{ error }, $_->{ desc };
    }

    # output to STDOUT
    my $stdout = stdout_from {
        ok  Bio::KBase::Templater::render_template(
                $data_dir->child( 'test.tt' )->stringify,
                { thing => 'world' },
            ), 'valid output, includes template vars, output to STDOUT';
    };
    my @content = map { s/(^\s*|\s*$)//g; $_ } grep { /\S/ } split /[\n\r]/, $stdout;
    cmp_deeply
        \@content,
        [ "Hello world", "G'day sport!" ],
        'content as expected';

    # output to a scalar
    my $string;
    ok  Bio::KBase::Templater::render_template(
            $data_dir->child( 'test.tt' )->stringify,
            {},
            \$string
        ), 'valid output, no template vars, saved to scalar ref';


    @content = map { s/(^\s*|\s*$)//g; $_ } grep { /\S/ } split /[\n\r]/, $string;
    cmp_deeply
        \@content,
        [ "Hello", "G'day sport!" ],
        'content as expected'
        or diag explain {
            string  => $string,
            content => \@content,
        };

    undef $string;
    ok  Bio::KBase::Templater::render_template(
            $data_dir->child( 'test.tt' )->stringify,
            { thing => 'world' },
            \$string
        ), 'valid output, includes template vars, saved to scalar ref';

    @content = map { s/(^\s*|\s*$)//g; $_ } grep { /\S/ } split /[\n\r]/, $string;
    cmp_deeply
        \@content,
        [ "Hello world", "G'day sport!" ],
        'content as expected'
        or diag explain {
            string  => $string,
            content => \@content,
        };

    my $temp_file = Path::Tiny->tempfile;
    ok  Bio::KBase::Templater::render_template(
            $data_dir->child( 'test.tt' )->stringify,
            { thing => 'world' },
            $temp_file->stringify,
        ), 'valid output, includes template vars, saved to a file';

    @content = map { s/(^\s*|\s*$)//g; $_ }
        grep { /\S/ }
        split /[\n\r]/, $temp_file->slurp_utf8;

    cmp_deeply
        \@content,
        [ "Hello world", "G'day sport!" ],
        'content as expected'
        or diag explain {
            file_slurp  => $temp_file->slurp_utf8,
            content     => \@content,
        };


};

done_testing;