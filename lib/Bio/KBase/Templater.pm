package Bio::KBase::Templater;

use strict;
use warnings;

use JSON::MaybeXS;
use Template;
use Template::Plugin::JSON;
use Carp qw( croak );

use Exporter 'import';

our @EXPORT_OK = qw( render_template );

=head2 render_template

Given a template, $template_file, populate it with $template_data and send the
output to $output. Very thin wrapper around Template::Toolkit's 'process' that
includes TT object initialisation.

Args:

$template       # input template; possible formats:
                #   - filename (absolute or relative to INCLUDE_PATH)
                #   - file handle reference
                #   - GLOB from which template can be read

$template_data  # data to use in the template (hashref; optional)

$output         # where to write the output to; possible formats:
                #   - filename (absolute)
                #   - open file GLOB
                #   - reference to a scalar variable to append output to
                #   - reference to a sub which is called with output as a param
                #   - reference to any object with a print() method

$arguments      # optional arguments to set binmode or IO layer (e.g. utf8)
                # defaults to utf-8

$config         # template engine configuration

Returns:

$output, the populated template

=cut

sub render_template {
    my ( $template, $template_data, $output, $arguments, $config ) = @_;

    $config //= {
        TRIM        => 1,
        ABSOLUTE    => 1,
        RELATIVE    => 1,
    };

    $arguments  //= { binmode => ':utf8' };

    my $tt      = Template->new( $config )
        or croak 'Template initialisation error: ' . $Template::ERROR;

    my @arguments = ( $template, $template_data );
    push @arguments, ( $output, $arguments )
        if defined $output;

    $tt->process( @arguments )
        or croak 'Template rendering error: ' . $tt->error();

    return 1;

}

1;