########################################################################
# Bio::KBase::ObjectAPI::Exceptions - Object Oriented Exceptions for KBase object API
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-08-14
########################################################################
package Bio::KBase::ObjectAPI::Exceptions;
use strict;
use warnings;

=head1 Bio::KBase::ObjectAPI::Exceptions

Structured exceptions used in KBase

=head2 Bio::KBase::ObjectAPI::Exception::CLI
Base Class for exceptions that implement a CLI reporting function

=head3 cli_error_text

Returns a string describing the error, formatted to be displayed
to the user.

=head2 Bio::KBase::ObjectAPI::Exception::NoDatabase

Error when there is no database configured for the KBase object API

=cut

use Exception::Class (
    'Bio::KBase::ObjectAPI::Exception::CLI' => {
        description => "Base class for exceptions that support cli_error_text",
    },
    'Bio::KBase::ObjectAPI::Exception::Basic' => {
        isa         => "Bio::KBase::ObjectAPI::Exception::CLI",
        description => "A generic exception with a message",
        fields      => [qw( message )],
      },
    'Bio::KBase::ObjectAPI::Exception::Database' => {
        isa => "Bio::KBase::ObjectAPI::Exception::CLI",
        description => "Exception with database"
    },
    'Bio::KBase::ObjectAPI::Exception::NoDatabase' => {
        isa => "Bio::KBase::ObjectAPI::Exception::Database",
        description => "When there is no database configuration",
    },
    'Bio::KBase::ObjectAPI::Exception::DatabaseConfigError' => {
        isa => "Bio::KBase::ObjectAPI::Exception::Database",
        description => "For invalid database configuration",
        fields => [qw( configText dbName )],
    },
    'Bio::KBase::ObjectAPI::Exception::BadReference' => {
        isa => "Bio::KBase::ObjectAPI::Exception::CLI",
        description => "When a bad reference string is passed into a function",
        fields => [qw( refstr )],
    },
    'Bio::KBase::ObjectAPI::Exception::InvalidAttribute' => {
        isa => "Bio::KBase::ObjectAPI::Exception::CLI",
        description => "Error trying to acess an attribute that an object does not have",
        fields => [qw( object invalid_attribute )],
    },
    'Bio::KBase::ObjectAPI::Exception::BadObjectLink' => {
        isa => "Bio::KBase::ObjectAPI::Exception::CLI",
        description => "For when object-links are not resolveable",
        fields => [qw(
            searchSource searchBaseObject searchBaseType
            searchAttribute searchUUID errorText
        )],
    },
    'Bio::KBase::ObjectAPI::Exception::MissingConfig' => {
        isa => "Bio::KBase::ObjectAPI::Exception::CLI",
        description => "Error when a config value is not set",
        fields => [qw( variable message )],
    },
);
1;

package Bio::KBase::ObjectAPI::Exception::CLI;
use strict;
use warnings;
sub cli_error_text {
    return "An unknown error occured.\n";
}
1;

package Bio::KBase::ObjectAPI::Exception::Basic;
use strict;
use warnings;
sub cli_error_text {
    my ($self) = @_;
    my $message = $self->message;
    return "An error occured:\n$message";
}
1;

package Bio::KBase::ObjectAPI::Exception::NoDatabase;
use strict;
use warnings;
sub cli_error_text { return <<ND;
Unable to construct a database connection.
Configure a database with the "stores" command
to add a database. For usage, run: 

\$ stores help
ND
}
1;

package Bio::KBase::ObjectAPI::Exception::DatabaseConfigError;
sub cli_error_text {
    my ($self) = @_;
    my $dbName = $self->dbName;
    my $configText = $self->configText;
return <<ND;
Error configuring Database: $dbName
Got invalid configuration:
$configText
Use the "stores" command to reconfigure this database.
ND
}
1;

package Bio::KBase::ObjectAPI::Exception::BadReference;
sub cli_error_text {
    my $self = shift;
    my $refstr = $self->refstr;
    return <<ND;
Bad reference: $refstr

References take the form of:

    biochemistry/username/string or
    biochemistry/E29318E0-C209-11E1-9982-998743BA47CD

Where "biochemistry" is the type, "username" is probably
your username; run: "ms whoami" to find out. "string" can
be whatever you want but cannot contain slashes.

In the second case, pass in a specific object UUID.
ND
}
1;

package Bio::KBase::ObjectAPI::Exception::InvalidAttribute;
sub cli_error_text {
    my $self = shift;
    my $object = $self->object;
    my $tried  = $self->invalid_attribute;
    my $type   = $object->meta->name;
    my @attrs  = $object->meta->get_all_attributes;
    my $attr_string = join("\n", map { $_ = "\t".$_->name } @attrs);
    return <<ND;
Invalid attribute '$tried' for $type, available attributes:
$attr_string

ND
}
1;

package Bio::KBase::ObjectAPI::Exception::BadObjectLink;
sub cli_error_text {
    my $self = shift;
    my $sourceObject = $self->searchSource;
    my $baseObject   = $self->searchBaseObject;
    my $baseType     = $self->searchBaseType;
    my $attr         = $self->searchAttribute;
    my $uuid         = $self->searchUUID;
    my $errorText    = $self->errorText;
    my $baseObjectClassName = "< an unknown class >";
    $baseObjectClassName = $baseObject->meta->name if defined $baseObject;
    my $sourceObjectClassName = $sourceObject->meta->name;
    return <<ND;
Bad Object Link in instance of $sourceObjectClassName.
Attempting to link to an object accessible via:
$baseObjectClassName, ($baseType)
under the attribute "$attr" with the UUID:
    $uuid

$errorText
ND
}
1;

package Bio::KBase::ObjectAPI::Exception::MissingConfig;
sub cli_error_text {
    my $self = shift;
    my $variable = $self->variable;
    my $message  = $self->message;
    return <<ND;
$variable configuration is undefined!
$message
    \$ ms config $variable=VALUE
ND
}
1;
