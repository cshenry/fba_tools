package KBaseTestContext;

use strict;
use warnings;

# A module containing test helpers and data

use Test::Most;
use Bio::KBase::Context;
use fba_tools::fba_toolsImpl;

my $impl;

sub base_dir { '/kb/module/' }

sub test_ws  { 'chenry:narrative_1504151898593' }

=head3

Create a new fba_tools::fba_toolsImpl object, bailing out of the rest of the
tests if the object cannot be created.

=cut

sub init_fba_tools_handler {

    unless ( $impl ) {
        subtest 'creating fba tools implementation' => sub {

            lives_ok {
                Bio::KBase::Context::create_context_from_client_config();
                $impl = fba_tools::fba_toolsImpl->new();
            } 'set up fba_tools implementation OK'

                or BAIL_OUT 'Cannot proceed without fba_tools impl running';

            isa_ok $impl, 'fba_tools::fba_toolsImpl';

        };
    }

    return $impl;

}


1;
