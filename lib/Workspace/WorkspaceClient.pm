package Workspace::WorkspaceClient;

use JSON::RPC::Client;
use POSIX;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
my $get_time = sub { time, 0 };
eval {
    require Time::HiRes;
    $get_time = sub { Time::HiRes::gettimeofday() };
};

use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

Workspace::WorkspaceClient

=head1 DESCRIPTION


The Workspace Service (WSS) is primarily a language independent remote storage
and retrieval system for KBase typed objects (TO) defined with the KBase
Interface Description Language (KIDL). It has the following primary features:
- Immutable storage of TOs with
        - user defined metadata 
        - data provenance
- Versioning of TOs
- Referencing from TO to TO
- Typechecking of all saved objects against a KIDL specification
- Collecting typed objects into a workspace
- Sharing workspaces with specific KBase users or the world
- Freezing and publishing workspaces


=cut

sub new
{
    my($class, $url, @args) = @_;
    

    my $self = {
	client => Workspace::WorkspaceClient::RpcClient->new,
	url => $url,
	headers => [],
    };

    chomp($self->{hostname} = `hostname`);
    $self->{hostname} ||= 'unknown-host';

    #
    # Set up for propagating KBRPC_TAG and KBRPC_METADATA environment variables through
    # to invoked services. If these values are not set, we create a new tag
    # and a metadata field with basic information about the invoking script.
    #
    if ($ENV{KBRPC_TAG})
    {
	$self->{kbrpc_tag} = $ENV{KBRPC_TAG};
    }
    else
    {
	my ($t, $us) = &$get_time();
	$us = sprintf("%06d", $us);
	my $ts = strftime("%Y-%m-%dT%H:%M:%S.${us}Z", gmtime $t);
	$self->{kbrpc_tag} = "C:$0:$self->{hostname}:$$:$ts";
    }
    push(@{$self->{headers}}, 'Kbrpc-Tag', $self->{kbrpc_tag});

    if ($ENV{KBRPC_METADATA})
    {
	$self->{kbrpc_metadata} = $ENV{KBRPC_METADATA};
	push(@{$self->{headers}}, 'Kbrpc-Metadata', $self->{kbrpc_metadata});
    }

    if ($ENV{KBRPC_ERROR_DEST})
    {
	$self->{kbrpc_error_dest} = $ENV{KBRPC_ERROR_DEST};
	push(@{$self->{headers}}, 'Kbrpc-Errordest', $self->{kbrpc_error_dest});
    }

    #
    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.

    {
	my %arg_hash2 = @args;
	if (exists $arg_hash2{"token"}) {
	    $self->{token} = $arg_hash2{"token"};
	} elsif (exists $arg_hash2{"user_id"}) {
	    my $token = Bio::KBase::AuthToken->new(@args);
	    if (!$token->error_message) {
	        $self->{token} = $token->token;
	    }
	}
	
	if (exists $self->{token})
	{
	    $self->{client}->{token} = $self->{token};
	}
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 ver

  $ver = $obj->ver()

=over 4

=item Parameter and return types

=begin html

<pre>
$ver is a string

</pre>

=end html

=begin text

$ver is a string


=end text

=item Description

Returns the version of the workspace service.

=back

=cut

 sub ver
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 0)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function ver (received $n, expecting 0)");
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.ver",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'ver',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method ver",
					    status_line => $self->{client}->status_line,
					    method_name => 'ver',
				       );
    }
}
 


=head2 create_workspace

  $info = $obj->create_workspace($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.CreateWorkspaceParams
$info is a Workspace.workspace_info
CreateWorkspaceParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	globalread has a value which is a Workspace.permission
	description has a value which is a string
	meta has a value which is a Workspace.usermeta
ws_name is a string
permission is a string
usermeta is a reference to a hash where the key is a string and the value is a string
workspace_info is a reference to a list containing 9 items:
	0: (id) a Workspace.ws_id
	1: (workspace) a Workspace.ws_name
	2: (owner) a Workspace.username
	3: (moddate) a Workspace.timestamp
	4: (max_objid) an int
	5: (user_permission) a Workspace.permission
	6: (globalread) a Workspace.permission
	7: (lockstat) a Workspace.lock_status
	8: (metadata) a Workspace.usermeta
ws_id is an int
username is a string
timestamp is a string
lock_status is a string

</pre>

=end html

=begin text

$params is a Workspace.CreateWorkspaceParams
$info is a Workspace.workspace_info
CreateWorkspaceParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	globalread has a value which is a Workspace.permission
	description has a value which is a string
	meta has a value which is a Workspace.usermeta
ws_name is a string
permission is a string
usermeta is a reference to a hash where the key is a string and the value is a string
workspace_info is a reference to a list containing 9 items:
	0: (id) a Workspace.ws_id
	1: (workspace) a Workspace.ws_name
	2: (owner) a Workspace.username
	3: (moddate) a Workspace.timestamp
	4: (max_objid) an int
	5: (user_permission) a Workspace.permission
	6: (globalread) a Workspace.permission
	7: (lockstat) a Workspace.lock_status
	8: (metadata) a Workspace.usermeta
ws_id is an int
username is a string
timestamp is a string
lock_status is a string


=end text

=item Description

Creates a new workspace.

=back

=cut

 sub create_workspace
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function create_workspace (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to create_workspace:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'create_workspace');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.create_workspace",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'create_workspace',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method create_workspace",
					    status_line => $self->{client}->status_line,
					    method_name => 'create_workspace',
				       );
    }
}
 


=head2 alter_workspace_metadata

  $obj->alter_workspace_metadata($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.AlterWorkspaceMetadataParams
AlterWorkspaceMetadataParams is a reference to a hash where the following keys are defined:
	wsi has a value which is a Workspace.WorkspaceIdentity
	new has a value which is a Workspace.usermeta
	remove has a value which is a reference to a list where each element is a string
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$params is a Workspace.AlterWorkspaceMetadataParams
AlterWorkspaceMetadataParams is a reference to a hash where the following keys are defined:
	wsi has a value which is a Workspace.WorkspaceIdentity
	new has a value which is a Workspace.usermeta
	remove has a value which is a reference to a list where each element is a string
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description

Change the metadata associated with a workspace.

=back

=cut

 sub alter_workspace_metadata
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function alter_workspace_metadata (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to alter_workspace_metadata:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'alter_workspace_metadata');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.alter_workspace_metadata",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'alter_workspace_metadata',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method alter_workspace_metadata",
					    status_line => $self->{client}->status_line,
					    method_name => 'alter_workspace_metadata',
				       );
    }
}
 


=head2 clone_workspace

  $info = $obj->clone_workspace($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.CloneWorkspaceParams
$info is a Workspace.workspace_info
CloneWorkspaceParams is a reference to a hash where the following keys are defined:
	wsi has a value which is a Workspace.WorkspaceIdentity
	workspace has a value which is a Workspace.ws_name
	globalread has a value which is a Workspace.permission
	description has a value which is a string
	meta has a value which is a Workspace.usermeta
	exclude has a value which is a reference to a list where each element is a Workspace.ObjectIdentity
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
permission is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
workspace_info is a reference to a list containing 9 items:
	0: (id) a Workspace.ws_id
	1: (workspace) a Workspace.ws_name
	2: (owner) a Workspace.username
	3: (moddate) a Workspace.timestamp
	4: (max_objid) an int
	5: (user_permission) a Workspace.permission
	6: (globalread) a Workspace.permission
	7: (lockstat) a Workspace.lock_status
	8: (metadata) a Workspace.usermeta
username is a string
timestamp is a string
lock_status is a string

</pre>

=end html

=begin text

$params is a Workspace.CloneWorkspaceParams
$info is a Workspace.workspace_info
CloneWorkspaceParams is a reference to a hash where the following keys are defined:
	wsi has a value which is a Workspace.WorkspaceIdentity
	workspace has a value which is a Workspace.ws_name
	globalread has a value which is a Workspace.permission
	description has a value which is a string
	meta has a value which is a Workspace.usermeta
	exclude has a value which is a reference to a list where each element is a Workspace.ObjectIdentity
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
permission is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
workspace_info is a reference to a list containing 9 items:
	0: (id) a Workspace.ws_id
	1: (workspace) a Workspace.ws_name
	2: (owner) a Workspace.username
	3: (moddate) a Workspace.timestamp
	4: (max_objid) an int
	5: (user_permission) a Workspace.permission
	6: (globalread) a Workspace.permission
	7: (lockstat) a Workspace.lock_status
	8: (metadata) a Workspace.usermeta
username is a string
timestamp is a string
lock_status is a string


=end text

=item Description

Clones a workspace.

=back

=cut

 sub clone_workspace
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function clone_workspace (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to clone_workspace:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'clone_workspace');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.clone_workspace",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'clone_workspace',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method clone_workspace",
					    status_line => $self->{client}->status_line,
					    method_name => 'clone_workspace',
				       );
    }
}
 


=head2 lock_workspace

  $info = $obj->lock_workspace($wsi)

=over 4

=item Parameter and return types

=begin html

<pre>
$wsi is a Workspace.WorkspaceIdentity
$info is a Workspace.workspace_info
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
workspace_info is a reference to a list containing 9 items:
	0: (id) a Workspace.ws_id
	1: (workspace) a Workspace.ws_name
	2: (owner) a Workspace.username
	3: (moddate) a Workspace.timestamp
	4: (max_objid) an int
	5: (user_permission) a Workspace.permission
	6: (globalread) a Workspace.permission
	7: (lockstat) a Workspace.lock_status
	8: (metadata) a Workspace.usermeta
username is a string
timestamp is a string
permission is a string
lock_status is a string
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$wsi is a Workspace.WorkspaceIdentity
$info is a Workspace.workspace_info
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
workspace_info is a reference to a list containing 9 items:
	0: (id) a Workspace.ws_id
	1: (workspace) a Workspace.ws_name
	2: (owner) a Workspace.username
	3: (moddate) a Workspace.timestamp
	4: (max_objid) an int
	5: (user_permission) a Workspace.permission
	6: (globalread) a Workspace.permission
	7: (lockstat) a Workspace.lock_status
	8: (metadata) a Workspace.usermeta
username is a string
timestamp is a string
permission is a string
lock_status is a string
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description

Lock a workspace, preventing further changes.

        WARNING: Locking a workspace is permanent. A workspace, once locked,
        cannot be unlocked.
        
        The only changes allowed for a locked workspace are changing user
        based permissions or making a private workspace globally readable,
        thus permanently publishing the workspace. A locked, globally readable
        workspace cannot be made private.

=back

=cut

 sub lock_workspace
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function lock_workspace (received $n, expecting 1)");
    }
    {
	my($wsi) = @args;

	my @_bad_arguments;
        (ref($wsi) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"wsi\" (value was \"$wsi\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to lock_workspace:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'lock_workspace');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.lock_workspace",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'lock_workspace',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method lock_workspace",
					    status_line => $self->{client}->status_line,
					    method_name => 'lock_workspace',
				       );
    }
}
 


=head2 get_workspacemeta

  $metadata = $obj->get_workspacemeta($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.get_workspacemeta_params
$metadata is a Workspace.workspace_metadata
get_workspacemeta_params is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
	auth has a value which is a string
ws_name is a string
ws_id is an int
workspace_metadata is a reference to a list containing 7 items:
	0: (id) a Workspace.ws_name
	1: (owner) a Workspace.username
	2: (moddate) a Workspace.timestamp
	3: (objects) an int
	4: (user_permission) a Workspace.permission
	5: (global_permission) a Workspace.permission
	6: (num_id) a Workspace.ws_id
username is a string
timestamp is a string
permission is a string

</pre>

=end html

=begin text

$params is a Workspace.get_workspacemeta_params
$metadata is a Workspace.workspace_metadata
get_workspacemeta_params is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
	auth has a value which is a string
ws_name is a string
ws_id is an int
workspace_metadata is a reference to a list containing 7 items:
	0: (id) a Workspace.ws_name
	1: (owner) a Workspace.username
	2: (moddate) a Workspace.timestamp
	3: (objects) an int
	4: (user_permission) a Workspace.permission
	5: (global_permission) a Workspace.permission
	6: (num_id) a Workspace.ws_id
username is a string
timestamp is a string
permission is a string


=end text

=item Description

Retrieves the metadata associated with the specified workspace.
Provided for backwards compatibility. 
@deprecated Workspace.get_workspace_info

=back

=cut

 sub get_workspacemeta
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_workspacemeta (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_workspacemeta:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_workspacemeta');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_workspacemeta",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_workspacemeta',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_workspacemeta",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_workspacemeta',
				       );
    }
}
 


=head2 get_workspace_info

  $info = $obj->get_workspace_info($wsi)

=over 4

=item Parameter and return types

=begin html

<pre>
$wsi is a Workspace.WorkspaceIdentity
$info is a Workspace.workspace_info
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
workspace_info is a reference to a list containing 9 items:
	0: (id) a Workspace.ws_id
	1: (workspace) a Workspace.ws_name
	2: (owner) a Workspace.username
	3: (moddate) a Workspace.timestamp
	4: (max_objid) an int
	5: (user_permission) a Workspace.permission
	6: (globalread) a Workspace.permission
	7: (lockstat) a Workspace.lock_status
	8: (metadata) a Workspace.usermeta
username is a string
timestamp is a string
permission is a string
lock_status is a string
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$wsi is a Workspace.WorkspaceIdentity
$info is a Workspace.workspace_info
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
workspace_info is a reference to a list containing 9 items:
	0: (id) a Workspace.ws_id
	1: (workspace) a Workspace.ws_name
	2: (owner) a Workspace.username
	3: (moddate) a Workspace.timestamp
	4: (max_objid) an int
	5: (user_permission) a Workspace.permission
	6: (globalread) a Workspace.permission
	7: (lockstat) a Workspace.lock_status
	8: (metadata) a Workspace.usermeta
username is a string
timestamp is a string
permission is a string
lock_status is a string
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description

Get information associated with a workspace.

=back

=cut

 sub get_workspace_info
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_workspace_info (received $n, expecting 1)");
    }
    {
	my($wsi) = @args;

	my @_bad_arguments;
        (ref($wsi) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"wsi\" (value was \"$wsi\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_workspace_info:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_workspace_info');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_workspace_info",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_workspace_info',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_workspace_info",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_workspace_info',
				       );
    }
}
 


=head2 get_workspace_description

  $description = $obj->get_workspace_description($wsi)

=over 4

=item Parameter and return types

=begin html

<pre>
$wsi is a Workspace.WorkspaceIdentity
$description is a string
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int

</pre>

=end html

=begin text

$wsi is a Workspace.WorkspaceIdentity
$description is a string
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int


=end text

=item Description

Get a workspace's description.

=back

=cut

 sub get_workspace_description
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_workspace_description (received $n, expecting 1)");
    }
    {
	my($wsi) = @args;

	my @_bad_arguments;
        (ref($wsi) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"wsi\" (value was \"$wsi\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_workspace_description:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_workspace_description');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_workspace_description",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_workspace_description',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_workspace_description",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_workspace_description',
				       );
    }
}
 


=head2 set_permissions

  $obj->set_permissions($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.SetPermissionsParams
SetPermissionsParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
	new_permission has a value which is a Workspace.permission
	users has a value which is a reference to a list where each element is a Workspace.username
ws_name is a string
ws_id is an int
permission is a string
username is a string

</pre>

=end html

=begin text

$params is a Workspace.SetPermissionsParams
SetPermissionsParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
	new_permission has a value which is a Workspace.permission
	users has a value which is a reference to a list where each element is a Workspace.username
ws_name is a string
ws_id is an int
permission is a string
username is a string


=end text

=item Description

Set permissions for a workspace.

=back

=cut

 sub set_permissions
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function set_permissions (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to set_permissions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'set_permissions');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.set_permissions",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'set_permissions',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method set_permissions",
					    status_line => $self->{client}->status_line,
					    method_name => 'set_permissions',
				       );
    }
}
 


=head2 set_global_permission

  $obj->set_global_permission($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.SetGlobalPermissionsParams
SetGlobalPermissionsParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
	new_permission has a value which is a Workspace.permission
ws_name is a string
ws_id is an int
permission is a string

</pre>

=end html

=begin text

$params is a Workspace.SetGlobalPermissionsParams
SetGlobalPermissionsParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
	new_permission has a value which is a Workspace.permission
ws_name is a string
ws_id is an int
permission is a string


=end text

=item Description

Set the global permission for a workspace.

=back

=cut

 sub set_global_permission
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function set_global_permission (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to set_global_permission:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'set_global_permission');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.set_global_permission",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'set_global_permission',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method set_global_permission",
					    status_line => $self->{client}->status_line,
					    method_name => 'set_global_permission',
				       );
    }
}
 


=head2 set_workspace_description

  $obj->set_workspace_description($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.SetWorkspaceDescriptionParams
SetWorkspaceDescriptionParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
	description has a value which is a string
ws_name is a string
ws_id is an int

</pre>

=end html

=begin text

$params is a Workspace.SetWorkspaceDescriptionParams
SetWorkspaceDescriptionParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
	description has a value which is a string
ws_name is a string
ws_id is an int


=end text

=item Description

Set the description for a workspace.

=back

=cut

 sub set_workspace_description
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function set_workspace_description (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to set_workspace_description:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'set_workspace_description');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.set_workspace_description",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'set_workspace_description',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method set_workspace_description",
					    status_line => $self->{client}->status_line,
					    method_name => 'set_workspace_description',
				       );
    }
}
 


=head2 get_permissions_mass

  $perms = $obj->get_permissions_mass($mass)

=over 4

=item Parameter and return types

=begin html

<pre>
$mass is a Workspace.GetPermissionsMassParams
$perms is a Workspace.WorkspacePermissions
GetPermissionsMassParams is a reference to a hash where the following keys are defined:
	workspaces has a value which is a reference to a list where each element is a Workspace.WorkspaceIdentity
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
WorkspacePermissions is a reference to a hash where the following keys are defined:
	perms has a value which is a reference to a list where each element is a reference to a hash where the key is a Workspace.username and the value is a Workspace.permission
username is a string
permission is a string

</pre>

=end html

=begin text

$mass is a Workspace.GetPermissionsMassParams
$perms is a Workspace.WorkspacePermissions
GetPermissionsMassParams is a reference to a hash where the following keys are defined:
	workspaces has a value which is a reference to a list where each element is a Workspace.WorkspaceIdentity
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
WorkspacePermissions is a reference to a hash where the following keys are defined:
	perms has a value which is a reference to a list where each element is a reference to a hash where the key is a Workspace.username and the value is a Workspace.permission
username is a string
permission is a string


=end text

=item Description

Get permissions for multiple workspaces.

=back

=cut

 sub get_permissions_mass
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_permissions_mass (received $n, expecting 1)");
    }
    {
	my($mass) = @args;

	my @_bad_arguments;
        (ref($mass) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"mass\" (value was \"$mass\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_permissions_mass:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_permissions_mass');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_permissions_mass",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_permissions_mass',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_permissions_mass",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_permissions_mass',
				       );
    }
}
 


=head2 get_permissions

  $perms = $obj->get_permissions($wsi)

=over 4

=item Parameter and return types

=begin html

<pre>
$wsi is a Workspace.WorkspaceIdentity
$perms is a reference to a hash where the key is a Workspace.username and the value is a Workspace.permission
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
username is a string
permission is a string

</pre>

=end html

=begin text

$wsi is a Workspace.WorkspaceIdentity
$perms is a reference to a hash where the key is a Workspace.username and the value is a Workspace.permission
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
username is a string
permission is a string


=end text

=item Description

Get permissions for a workspace.
@deprecated get_permissions_mass

=back

=cut

 sub get_permissions
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_permissions (received $n, expecting 1)");
    }
    {
	my($wsi) = @args;

	my @_bad_arguments;
        (ref($wsi) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"wsi\" (value was \"$wsi\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_permissions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_permissions');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_permissions",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_permissions',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_permissions",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_permissions',
				       );
    }
}
 


=head2 save_object

  $metadata = $obj->save_object($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.save_object_params
$metadata is a Workspace.object_metadata
save_object_params is a reference to a hash where the following keys are defined:
	id has a value which is a Workspace.obj_name
	type has a value which is a Workspace.type_string
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	workspace has a value which is a Workspace.ws_name
	metadata has a value which is a reference to a hash where the key is a string and the value is a string
	auth has a value which is a string
obj_name is a string
type_string is a string
ws_name is a string
object_metadata is a reference to a list containing 12 items:
	0: (id) a Workspace.obj_name
	1: (type) a Workspace.type_string
	2: (moddate) a Workspace.timestamp
	3: (instance) an int
	4: (command) a string
	5: (lastmodifier) a Workspace.username
	6: (owner) a Workspace.username
	7: (workspace) a Workspace.ws_name
	8: (ref) a string
	9: (chsum) a string
	10: (metadata) a Workspace.usermeta
	11: (objid) a Workspace.obj_id
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
obj_id is an int

</pre>

=end html

=begin text

$params is a Workspace.save_object_params
$metadata is a Workspace.object_metadata
save_object_params is a reference to a hash where the following keys are defined:
	id has a value which is a Workspace.obj_name
	type has a value which is a Workspace.type_string
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	workspace has a value which is a Workspace.ws_name
	metadata has a value which is a reference to a hash where the key is a string and the value is a string
	auth has a value which is a string
obj_name is a string
type_string is a string
ws_name is a string
object_metadata is a reference to a list containing 12 items:
	0: (id) a Workspace.obj_name
	1: (type) a Workspace.type_string
	2: (moddate) a Workspace.timestamp
	3: (instance) an int
	4: (command) a string
	5: (lastmodifier) a Workspace.username
	6: (owner) a Workspace.username
	7: (workspace) a Workspace.ws_name
	8: (ref) a string
	9: (chsum) a string
	10: (metadata) a Workspace.usermeta
	11: (objid) a Workspace.obj_id
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
obj_id is an int


=end text

=item Description

Saves the input object data and metadata into the selected workspace,
returning the object_metadata of the saved object. Provided
for backwards compatibility.

@deprecated Workspace.save_objects

=back

=cut

 sub save_object
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function save_object (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to save_object:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'save_object');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.save_object",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'save_object',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method save_object",
					    status_line => $self->{client}->status_line,
					    method_name => 'save_object',
				       );
    }
}
 


=head2 save_objects

  $info = $obj->save_objects($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.SaveObjectsParams
$info is a reference to a list where each element is a Workspace.object_info
SaveObjectsParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
	objects has a value which is a reference to a list where each element is a Workspace.ObjectSaveData
ws_name is a string
ws_id is an int
ObjectSaveData is a reference to a hash where the following keys are defined:
	type has a value which is a Workspace.type_string
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	meta has a value which is a Workspace.usermeta
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	hidden has a value which is a Workspace.boolean
type_string is a string
obj_name is a string
obj_id is an int
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
timestamp is a string
epoch is an int
ref_string is a string
obj_ref is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
boolean is an int
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
username is a string

</pre>

=end html

=begin text

$params is a Workspace.SaveObjectsParams
$info is a reference to a list where each element is a Workspace.object_info
SaveObjectsParams is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
	objects has a value which is a reference to a list where each element is a Workspace.ObjectSaveData
ws_name is a string
ws_id is an int
ObjectSaveData is a reference to a hash where the following keys are defined:
	type has a value which is a Workspace.type_string
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	meta has a value which is a Workspace.usermeta
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	hidden has a value which is a Workspace.boolean
type_string is a string
obj_name is a string
obj_id is an int
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
timestamp is a string
epoch is an int
ref_string is a string
obj_ref is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
boolean is an int
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
username is a string


=end text

=item Description

Save objects to the workspace. Saving over a deleted object undeletes
it.

=back

=cut

 sub save_objects
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function save_objects (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to save_objects:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'save_objects');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.save_objects",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'save_objects',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method save_objects",
					    status_line => $self->{client}->status_line,
					    method_name => 'save_objects',
				       );
    }
}
 


=head2 get_object

  $output = $obj->get_object($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.get_object_params
$output is a Workspace.get_object_output
get_object_params is a reference to a hash where the following keys are defined:
	id has a value which is a Workspace.obj_name
	workspace has a value which is a Workspace.ws_name
	instance has a value which is an int
	auth has a value which is a string
obj_name is a string
ws_name is a string
get_object_output is a reference to a hash where the following keys are defined:
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	metadata has a value which is a Workspace.object_metadata
object_metadata is a reference to a list containing 12 items:
	0: (id) a Workspace.obj_name
	1: (type) a Workspace.type_string
	2: (moddate) a Workspace.timestamp
	3: (instance) an int
	4: (command) a string
	5: (lastmodifier) a Workspace.username
	6: (owner) a Workspace.username
	7: (workspace) a Workspace.ws_name
	8: (ref) a string
	9: (chsum) a string
	10: (metadata) a Workspace.usermeta
	11: (objid) a Workspace.obj_id
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
obj_id is an int

</pre>

=end html

=begin text

$params is a Workspace.get_object_params
$output is a Workspace.get_object_output
get_object_params is a reference to a hash where the following keys are defined:
	id has a value which is a Workspace.obj_name
	workspace has a value which is a Workspace.ws_name
	instance has a value which is an int
	auth has a value which is a string
obj_name is a string
ws_name is a string
get_object_output is a reference to a hash where the following keys are defined:
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	metadata has a value which is a Workspace.object_metadata
object_metadata is a reference to a list containing 12 items:
	0: (id) a Workspace.obj_name
	1: (type) a Workspace.type_string
	2: (moddate) a Workspace.timestamp
	3: (instance) an int
	4: (command) a string
	5: (lastmodifier) a Workspace.username
	6: (owner) a Workspace.username
	7: (workspace) a Workspace.ws_name
	8: (ref) a string
	9: (chsum) a string
	10: (metadata) a Workspace.usermeta
	11: (objid) a Workspace.obj_id
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
obj_id is an int


=end text

=item Description

Retrieves the specified object from the specified workspace.
Both the object data and metadata are returned.
Provided for backwards compatibility.

@deprecated Workspace.get_objects

=back

=cut

 sub get_object
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_object (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_object:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_object');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_object",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_object',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_object",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_object',
				       );
    }
}
 


=head2 get_object_provenance

  $data = $obj->get_object_provenance($object_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
$data is a reference to a list where each element is a Workspace.ObjectProvenanceInfo
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
ObjectProvenanceInfo is a reference to a hash where the following keys are defined:
	info has a value which is a Workspace.object_info
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	creator has a value which is a Workspace.username
	orig_wsid has a value which is a Workspace.ws_id
	created has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	refs has a value which is a reference to a list where each element is a Workspace.obj_ref
	copied has a value which is a Workspace.obj_ref
	copy_source_inaccessible has a value which is a Workspace.boolean
	extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
	handle_error has a value which is a string
	handle_stacktrace has a value which is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
epoch is an int
ref_string is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
boolean is an int
id_type is a string
extracted_id is a string

</pre>

=end html

=begin text

$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
$data is a reference to a list where each element is a Workspace.ObjectProvenanceInfo
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
ObjectProvenanceInfo is a reference to a hash where the following keys are defined:
	info has a value which is a Workspace.object_info
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	creator has a value which is a Workspace.username
	orig_wsid has a value which is a Workspace.ws_id
	created has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	refs has a value which is a reference to a list where each element is a Workspace.obj_ref
	copied has a value which is a Workspace.obj_ref
	copy_source_inaccessible has a value which is a Workspace.boolean
	extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
	handle_error has a value which is a string
	handle_stacktrace has a value which is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
epoch is an int
ref_string is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
boolean is an int
id_type is a string
extracted_id is a string


=end text

=item Description

DEPRECATED
Get object provenance from the workspace.

@deprecated Workspace.get_objects2

=back

=cut

 sub get_object_provenance
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_object_provenance (received $n, expecting 1)");
    }
    {
	my($object_ids) = @args;

	my @_bad_arguments;
        (ref($object_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"object_ids\" (value was \"$object_ids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_object_provenance:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_object_provenance');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_object_provenance",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_object_provenance',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_object_provenance",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_object_provenance',
				       );
    }
}
 


=head2 get_objects

  $data = $obj->get_objects($object_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
$data is a reference to a list where each element is a Workspace.ObjectData
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
ObjectData is a reference to a hash where the following keys are defined:
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	info has a value which is a Workspace.object_info
	path has a value which is a reference to a list where each element is a Workspace.obj_ref
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	creator has a value which is a Workspace.username
	orig_wsid has a value which is a Workspace.ws_id
	created has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	refs has a value which is a reference to a list where each element is a Workspace.obj_ref
	copied has a value which is a Workspace.obj_ref
	copy_source_inaccessible has a value which is a Workspace.boolean
	extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
	handle_error has a value which is a string
	handle_stacktrace has a value which is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
epoch is an int
ref_string is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
boolean is an int
id_type is a string
extracted_id is a string

</pre>

=end html

=begin text

$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
$data is a reference to a list where each element is a Workspace.ObjectData
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
ObjectData is a reference to a hash where the following keys are defined:
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	info has a value which is a Workspace.object_info
	path has a value which is a reference to a list where each element is a Workspace.obj_ref
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	creator has a value which is a Workspace.username
	orig_wsid has a value which is a Workspace.ws_id
	created has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	refs has a value which is a reference to a list where each element is a Workspace.obj_ref
	copied has a value which is a Workspace.obj_ref
	copy_source_inaccessible has a value which is a Workspace.boolean
	extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
	handle_error has a value which is a string
	handle_stacktrace has a value which is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
epoch is an int
ref_string is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
boolean is an int
id_type is a string
extracted_id is a string


=end text

=item Description

DEPRECATED
Get objects from the workspace.
@deprecated Workspace.get_objects2

=back

=cut

 sub get_objects
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_objects (received $n, expecting 1)");
    }
    {
	my($object_ids) = @args;

	my @_bad_arguments;
        (ref($object_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"object_ids\" (value was \"$object_ids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_objects:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_objects');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_objects",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_objects',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_objects",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_objects',
				       );
    }
}
 


=head2 get_objects2

  $results = $obj->get_objects2($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.GetObjects2Params
$results is a Workspace.GetObjects2Results
GetObjects2Params is a reference to a hash where the following keys are defined:
	objects has a value which is a reference to a list where each element is a Workspace.ObjectSpecification
	ignoreErrors has a value which is a Workspace.boolean
	no_data has a value which is a Workspace.boolean
ObjectSpecification is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.ref_string
	obj_path has a value which is a Workspace.ref_chain
	obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
	to_obj_path has a value which is a Workspace.ref_chain
	to_obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
	find_reference_path has a value which is a Workspace.boolean
	included has a value which is a reference to a list where each element is a Workspace.object_path
	strict_maps has a value which is a Workspace.boolean
	strict_arrays has a value which is a Workspace.boolean
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
ref_string is a string
ref_chain is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
obj_ref is a string
boolean is an int
object_path is a string
GetObjects2Results is a reference to a hash where the following keys are defined:
	data has a value which is a reference to a list where each element is a Workspace.ObjectData
ObjectData is a reference to a hash where the following keys are defined:
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	info has a value which is a Workspace.object_info
	path has a value which is a reference to a list where each element is a Workspace.obj_ref
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	creator has a value which is a Workspace.username
	orig_wsid has a value which is a Workspace.ws_id
	created has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	refs has a value which is a reference to a list where each element is a Workspace.obj_ref
	copied has a value which is a Workspace.obj_ref
	copy_source_inaccessible has a value which is a Workspace.boolean
	extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
	handle_error has a value which is a string
	handle_stacktrace has a value which is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
epoch is an int
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
id_type is a string
extracted_id is a string

</pre>

=end html

=begin text

$params is a Workspace.GetObjects2Params
$results is a Workspace.GetObjects2Results
GetObjects2Params is a reference to a hash where the following keys are defined:
	objects has a value which is a reference to a list where each element is a Workspace.ObjectSpecification
	ignoreErrors has a value which is a Workspace.boolean
	no_data has a value which is a Workspace.boolean
ObjectSpecification is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.ref_string
	obj_path has a value which is a Workspace.ref_chain
	obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
	to_obj_path has a value which is a Workspace.ref_chain
	to_obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
	find_reference_path has a value which is a Workspace.boolean
	included has a value which is a reference to a list where each element is a Workspace.object_path
	strict_maps has a value which is a Workspace.boolean
	strict_arrays has a value which is a Workspace.boolean
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
ref_string is a string
ref_chain is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
obj_ref is a string
boolean is an int
object_path is a string
GetObjects2Results is a reference to a hash where the following keys are defined:
	data has a value which is a reference to a list where each element is a Workspace.ObjectData
ObjectData is a reference to a hash where the following keys are defined:
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	info has a value which is a Workspace.object_info
	path has a value which is a reference to a list where each element is a Workspace.obj_ref
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	creator has a value which is a Workspace.username
	orig_wsid has a value which is a Workspace.ws_id
	created has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	refs has a value which is a reference to a list where each element is a Workspace.obj_ref
	copied has a value which is a Workspace.obj_ref
	copy_source_inaccessible has a value which is a Workspace.boolean
	extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
	handle_error has a value which is a string
	handle_stacktrace has a value which is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
epoch is an int
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
id_type is a string
extracted_id is a string


=end text

=item Description

Get objects from the workspace.

=back

=cut

 sub get_objects2
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_objects2 (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_objects2:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_objects2');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_objects2",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_objects2',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_objects2",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_objects2',
				       );
    }
}
 


=head2 get_object_subset

  $data = $obj->get_object_subset($sub_object_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$sub_object_ids is a reference to a list where each element is a Workspace.SubObjectIdentity
$data is a reference to a list where each element is a Workspace.ObjectData
SubObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
	included has a value which is a reference to a list where each element is a Workspace.object_path
	strict_maps has a value which is a Workspace.boolean
	strict_arrays has a value which is a Workspace.boolean
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
object_path is a string
boolean is an int
ObjectData is a reference to a hash where the following keys are defined:
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	info has a value which is a Workspace.object_info
	path has a value which is a reference to a list where each element is a Workspace.obj_ref
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	creator has a value which is a Workspace.username
	orig_wsid has a value which is a Workspace.ws_id
	created has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	refs has a value which is a reference to a list where each element is a Workspace.obj_ref
	copied has a value which is a Workspace.obj_ref
	copy_source_inaccessible has a value which is a Workspace.boolean
	extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
	handle_error has a value which is a string
	handle_stacktrace has a value which is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
epoch is an int
ref_string is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
id_type is a string
extracted_id is a string

</pre>

=end html

=begin text

$sub_object_ids is a reference to a list where each element is a Workspace.SubObjectIdentity
$data is a reference to a list where each element is a Workspace.ObjectData
SubObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
	included has a value which is a reference to a list where each element is a Workspace.object_path
	strict_maps has a value which is a Workspace.boolean
	strict_arrays has a value which is a Workspace.boolean
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
object_path is a string
boolean is an int
ObjectData is a reference to a hash where the following keys are defined:
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	info has a value which is a Workspace.object_info
	path has a value which is a reference to a list where each element is a Workspace.obj_ref
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	creator has a value which is a Workspace.username
	orig_wsid has a value which is a Workspace.ws_id
	created has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	refs has a value which is a reference to a list where each element is a Workspace.obj_ref
	copied has a value which is a Workspace.obj_ref
	copy_source_inaccessible has a value which is a Workspace.boolean
	extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
	handle_error has a value which is a string
	handle_stacktrace has a value which is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
epoch is an int
ref_string is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
id_type is a string
extracted_id is a string


=end text

=item Description

DEPRECATED
Get portions of objects from the workspace.

When selecting a subset of an array in an object, the returned
array is compressed to the size of the subset, but the ordering of
the array is maintained. For example, if the array stored at the
'feature' key of a Genome object has 4000 entries, and the object paths
provided are:
        /feature/7
        /feature/3015
        /feature/700
The returned feature array will be of length three and the entries will
consist, in order, of the 7th, 700th, and 3015th entries of the
original array.
@deprecated Workspace.get_objects2

=back

=cut

 sub get_object_subset
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_object_subset (received $n, expecting 1)");
    }
    {
	my($sub_object_ids) = @args;

	my @_bad_arguments;
        (ref($sub_object_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"sub_object_ids\" (value was \"$sub_object_ids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_object_subset:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_object_subset');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_object_subset",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_object_subset',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_object_subset",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_object_subset',
				       );
    }
}
 


=head2 get_object_history

  $history = $obj->get_object_history($object)

=over 4

=item Parameter and return types

=begin html

<pre>
$object is a Workspace.ObjectIdentity
$history is a reference to a list where each element is a Workspace.object_info
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$object is a Workspace.ObjectIdentity
$history is a reference to a list where each element is a Workspace.object_info
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description

Get an object's history. The version argument of the ObjectIdentity is
ignored.

=back

=cut

 sub get_object_history
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_object_history (received $n, expecting 1)");
    }
    {
	my($object) = @args;

	my @_bad_arguments;
        (ref($object) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"object\" (value was \"$object\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_object_history:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_object_history');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_object_history",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_object_history',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_object_history",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_object_history',
				       );
    }
}
 


=head2 list_referencing_objects

  $referrers = $obj->list_referencing_objects($object_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
$referrers is a reference to a list where each element is a reference to a list where each element is a Workspace.object_info
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
$referrers is a reference to a list where each element is a reference to a list where each element is a Workspace.object_info
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description

List objects that reference one or more specified objects. References
in the deleted state are not returned.

=back

=cut

 sub list_referencing_objects
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function list_referencing_objects (received $n, expecting 1)");
    }
    {
	my($object_ids) = @args;

	my @_bad_arguments;
        (ref($object_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"object_ids\" (value was \"$object_ids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to list_referencing_objects:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'list_referencing_objects');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.list_referencing_objects",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'list_referencing_objects',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method list_referencing_objects",
					    status_line => $self->{client}->status_line,
					    method_name => 'list_referencing_objects',
				       );
    }
}
 


=head2 list_referencing_object_counts

  $counts = $obj->list_referencing_object_counts($object_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
$counts is a reference to a list where each element is an int
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string

</pre>

=end html

=begin text

$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
$counts is a reference to a list where each element is an int
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string


=end text

=item Description

DEPRECATED

List the number of times objects have been referenced.

This count includes both provenance and object-to-object references
and, unlike list_referencing_objects, includes objects that are
inaccessible to the user.

@deprecated

=back

=cut

 sub list_referencing_object_counts
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function list_referencing_object_counts (received $n, expecting 1)");
    }
    {
	my($object_ids) = @args;

	my @_bad_arguments;
        (ref($object_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"object_ids\" (value was \"$object_ids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to list_referencing_object_counts:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'list_referencing_object_counts');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.list_referencing_object_counts",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'list_referencing_object_counts',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method list_referencing_object_counts",
					    status_line => $self->{client}->status_line,
					    method_name => 'list_referencing_object_counts',
				       );
    }
}
 


=head2 get_referenced_objects

  $data = $obj->get_referenced_objects($ref_chains)

=over 4

=item Parameter and return types

=begin html

<pre>
$ref_chains is a reference to a list where each element is a Workspace.ref_chain
$data is a reference to a list where each element is a Workspace.ObjectData
ref_chain is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
ObjectData is a reference to a hash where the following keys are defined:
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	info has a value which is a Workspace.object_info
	path has a value which is a reference to a list where each element is a Workspace.obj_ref
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	creator has a value which is a Workspace.username
	orig_wsid has a value which is a Workspace.ws_id
	created has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	refs has a value which is a reference to a list where each element is a Workspace.obj_ref
	copied has a value which is a Workspace.obj_ref
	copy_source_inaccessible has a value which is a Workspace.boolean
	extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
	handle_error has a value which is a string
	handle_stacktrace has a value which is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
epoch is an int
ref_string is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
boolean is an int
id_type is a string
extracted_id is a string

</pre>

=end html

=begin text

$ref_chains is a reference to a list where each element is a Workspace.ref_chain
$data is a reference to a list where each element is a Workspace.ObjectData
ref_chain is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
ObjectData is a reference to a hash where the following keys are defined:
	data has a value which is an UnspecifiedObject, which can hold any non-null object
	info has a value which is a Workspace.object_info
	path has a value which is a reference to a list where each element is a Workspace.obj_ref
	provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
	creator has a value which is a Workspace.username
	orig_wsid has a value which is a Workspace.ws_id
	created has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	refs has a value which is a reference to a list where each element is a Workspace.obj_ref
	copied has a value which is a Workspace.obj_ref
	copy_source_inaccessible has a value which is a Workspace.boolean
	extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
	handle_error has a value which is a string
	handle_stacktrace has a value which is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
ProvenanceAction is a reference to a hash where the following keys are defined:
	time has a value which is a Workspace.timestamp
	epoch has a value which is a Workspace.epoch
	caller has a value which is a string
	service has a value which is a string
	service_ver has a value which is a string
	method has a value which is a string
	method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
	script has a value which is a string
	script_ver has a value which is a string
	script_command_line has a value which is a string
	input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
	resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
	intermediate_incoming has a value which is a reference to a list where each element is a string
	intermediate_outgoing has a value which is a reference to a list where each element is a string
	external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
	subactions has a value which is a reference to a list where each element is a Workspace.SubAction
	custom has a value which is a reference to a hash where the key is a string and the value is a string
	description has a value which is a string
epoch is an int
ref_string is a string
ExternalDataUnit is a reference to a hash where the following keys are defined:
	resource_name has a value which is a string
	resource_url has a value which is a string
	resource_version has a value which is a string
	resource_release_date has a value which is a Workspace.timestamp
	resource_release_epoch has a value which is a Workspace.epoch
	data_url has a value which is a string
	data_id has a value which is a string
	description has a value which is a string
SubAction is a reference to a hash where the following keys are defined:
	name has a value which is a string
	ver has a value which is a string
	code_url has a value which is a string
	commit has a value which is a string
	endpoint_url has a value which is a string
boolean is an int
id_type is a string
extracted_id is a string


=end text

=item Description

DEPRECATED

        Get objects by references from other objects.

        NOTE: In the vast majority of cases, this method is not necessary and
        get_objects should be used instead. 
        
        get_referenced_objects guarantees that a user that has access to an
        object can always see a) objects that are referenced inside the object
        and b) objects that are referenced in the object's provenance. This
        ensures that the user has visibility into the entire provenance of the
        object and the object's object dependencies (e.g. references).
        
        The user must have at least read access to the first object in each
        reference chain, but need not have access to any further objects in
        the chain, and those objects may be deleted.
        
        @deprecated Workspace.get_objects2

=back

=cut

 sub get_referenced_objects
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_referenced_objects (received $n, expecting 1)");
    }
    {
	my($ref_chains) = @args;

	my @_bad_arguments;
        (ref($ref_chains) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ref_chains\" (value was \"$ref_chains\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_referenced_objects:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_referenced_objects');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_referenced_objects",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_referenced_objects',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_referenced_objects",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_referenced_objects',
				       );
    }
}
 


=head2 list_workspaces

  $workspaces = $obj->list_workspaces($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.list_workspaces_params
$workspaces is a reference to a list where each element is a Workspace.workspace_metadata
list_workspaces_params is a reference to a hash where the following keys are defined:
	auth has a value which is a string
	excludeGlobal has a value which is a Workspace.boolean
boolean is an int
workspace_metadata is a reference to a list containing 7 items:
	0: (id) a Workspace.ws_name
	1: (owner) a Workspace.username
	2: (moddate) a Workspace.timestamp
	3: (objects) an int
	4: (user_permission) a Workspace.permission
	5: (global_permission) a Workspace.permission
	6: (num_id) a Workspace.ws_id
ws_name is a string
username is a string
timestamp is a string
permission is a string
ws_id is an int

</pre>

=end html

=begin text

$params is a Workspace.list_workspaces_params
$workspaces is a reference to a list where each element is a Workspace.workspace_metadata
list_workspaces_params is a reference to a hash where the following keys are defined:
	auth has a value which is a string
	excludeGlobal has a value which is a Workspace.boolean
boolean is an int
workspace_metadata is a reference to a list containing 7 items:
	0: (id) a Workspace.ws_name
	1: (owner) a Workspace.username
	2: (moddate) a Workspace.timestamp
	3: (objects) an int
	4: (user_permission) a Workspace.permission
	5: (global_permission) a Workspace.permission
	6: (num_id) a Workspace.ws_id
ws_name is a string
username is a string
timestamp is a string
permission is a string
ws_id is an int


=end text

=item Description

Lists the metadata of all workspaces a user has access to. Provided for
backwards compatibility - to be replaced by the functionality of
list_workspace_info

@deprecated Workspace.list_workspace_info

=back

=cut

 sub list_workspaces
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function list_workspaces (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to list_workspaces:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'list_workspaces');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.list_workspaces",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'list_workspaces',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method list_workspaces",
					    status_line => $self->{client}->status_line,
					    method_name => 'list_workspaces',
				       );
    }
}
 


=head2 list_workspace_info

  $wsinfo = $obj->list_workspace_info($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.ListWorkspaceInfoParams
$wsinfo is a reference to a list where each element is a Workspace.workspace_info
ListWorkspaceInfoParams is a reference to a hash where the following keys are defined:
	perm has a value which is a Workspace.permission
	owners has a value which is a reference to a list where each element is a Workspace.username
	meta has a value which is a Workspace.usermeta
	after has a value which is a Workspace.timestamp
	before has a value which is a Workspace.timestamp
	after_epoch has a value which is a Workspace.epoch
	before_epoch has a value which is a Workspace.epoch
	excludeGlobal has a value which is a Workspace.boolean
	showDeleted has a value which is a Workspace.boolean
	showOnlyDeleted has a value which is a Workspace.boolean
permission is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
timestamp is a string
epoch is an int
boolean is an int
workspace_info is a reference to a list containing 9 items:
	0: (id) a Workspace.ws_id
	1: (workspace) a Workspace.ws_name
	2: (owner) a Workspace.username
	3: (moddate) a Workspace.timestamp
	4: (max_objid) an int
	5: (user_permission) a Workspace.permission
	6: (globalread) a Workspace.permission
	7: (lockstat) a Workspace.lock_status
	8: (metadata) a Workspace.usermeta
ws_id is an int
ws_name is a string
lock_status is a string

</pre>

=end html

=begin text

$params is a Workspace.ListWorkspaceInfoParams
$wsinfo is a reference to a list where each element is a Workspace.workspace_info
ListWorkspaceInfoParams is a reference to a hash where the following keys are defined:
	perm has a value which is a Workspace.permission
	owners has a value which is a reference to a list where each element is a Workspace.username
	meta has a value which is a Workspace.usermeta
	after has a value which is a Workspace.timestamp
	before has a value which is a Workspace.timestamp
	after_epoch has a value which is a Workspace.epoch
	before_epoch has a value which is a Workspace.epoch
	excludeGlobal has a value which is a Workspace.boolean
	showDeleted has a value which is a Workspace.boolean
	showOnlyDeleted has a value which is a Workspace.boolean
permission is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
timestamp is a string
epoch is an int
boolean is an int
workspace_info is a reference to a list containing 9 items:
	0: (id) a Workspace.ws_id
	1: (workspace) a Workspace.ws_name
	2: (owner) a Workspace.username
	3: (moddate) a Workspace.timestamp
	4: (max_objid) an int
	5: (user_permission) a Workspace.permission
	6: (globalread) a Workspace.permission
	7: (lockstat) a Workspace.lock_status
	8: (metadata) a Workspace.usermeta
ws_id is an int
ws_name is a string
lock_status is a string


=end text

=item Description

List workspaces viewable by the user.

=back

=cut

 sub list_workspace_info
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function list_workspace_info (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to list_workspace_info:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'list_workspace_info');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.list_workspace_info",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'list_workspace_info',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method list_workspace_info",
					    status_line => $self->{client}->status_line,
					    method_name => 'list_workspace_info',
				       );
    }
}
 


=head2 list_workspace_objects

  $objects = $obj->list_workspace_objects($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.list_workspace_objects_params
$objects is a reference to a list where each element is a Workspace.object_metadata
list_workspace_objects_params is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	type has a value which is a Workspace.type_string
	showDeletedObject has a value which is a Workspace.boolean
	auth has a value which is a string
ws_name is a string
type_string is a string
boolean is an int
object_metadata is a reference to a list containing 12 items:
	0: (id) a Workspace.obj_name
	1: (type) a Workspace.type_string
	2: (moddate) a Workspace.timestamp
	3: (instance) an int
	4: (command) a string
	5: (lastmodifier) a Workspace.username
	6: (owner) a Workspace.username
	7: (workspace) a Workspace.ws_name
	8: (ref) a string
	9: (chsum) a string
	10: (metadata) a Workspace.usermeta
	11: (objid) a Workspace.obj_id
obj_name is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
obj_id is an int

</pre>

=end html

=begin text

$params is a Workspace.list_workspace_objects_params
$objects is a reference to a list where each element is a Workspace.object_metadata
list_workspace_objects_params is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	type has a value which is a Workspace.type_string
	showDeletedObject has a value which is a Workspace.boolean
	auth has a value which is a string
ws_name is a string
type_string is a string
boolean is an int
object_metadata is a reference to a list containing 12 items:
	0: (id) a Workspace.obj_name
	1: (type) a Workspace.type_string
	2: (moddate) a Workspace.timestamp
	3: (instance) an int
	4: (command) a string
	5: (lastmodifier) a Workspace.username
	6: (owner) a Workspace.username
	7: (workspace) a Workspace.ws_name
	8: (ref) a string
	9: (chsum) a string
	10: (metadata) a Workspace.usermeta
	11: (objid) a Workspace.obj_id
obj_name is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
obj_id is an int


=end text

=item Description

Lists the metadata of all objects in the specified workspace with the
specified type (or with any type). Provided for backwards compatibility.

@deprecated Workspace.list_objects

=back

=cut

 sub list_workspace_objects
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function list_workspace_objects (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to list_workspace_objects:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'list_workspace_objects');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.list_workspace_objects",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'list_workspace_objects',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method list_workspace_objects",
					    status_line => $self->{client}->status_line,
					    method_name => 'list_workspace_objects',
				       );
    }
}
 


=head2 list_objects

  $objinfo = $obj->list_objects($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.ListObjectsParams
$objinfo is a reference to a list where each element is a Workspace.object_info
ListObjectsParams is a reference to a hash where the following keys are defined:
	workspaces has a value which is a reference to a list where each element is a Workspace.ws_name
	ids has a value which is a reference to a list where each element is a Workspace.ws_id
	type has a value which is a Workspace.type_string
	perm has a value which is a Workspace.permission
	savedby has a value which is a reference to a list where each element is a Workspace.username
	meta has a value which is a Workspace.usermeta
	after has a value which is a Workspace.timestamp
	before has a value which is a Workspace.timestamp
	after_epoch has a value which is a Workspace.epoch
	before_epoch has a value which is a Workspace.epoch
	minObjectID has a value which is a Workspace.obj_id
	maxObjectID has a value which is a Workspace.obj_id
	showDeleted has a value which is a Workspace.boolean
	showOnlyDeleted has a value which is a Workspace.boolean
	showHidden has a value which is a Workspace.boolean
	showAllVersions has a value which is a Workspace.boolean
	includeMetadata has a value which is a Workspace.boolean
	excludeGlobal has a value which is a Workspace.boolean
	limit has a value which is an int
ws_name is a string
ws_id is an int
type_string is a string
permission is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
timestamp is a string
epoch is an int
obj_id is an int
boolean is an int
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
obj_name is a string

</pre>

=end html

=begin text

$params is a Workspace.ListObjectsParams
$objinfo is a reference to a list where each element is a Workspace.object_info
ListObjectsParams is a reference to a hash where the following keys are defined:
	workspaces has a value which is a reference to a list where each element is a Workspace.ws_name
	ids has a value which is a reference to a list where each element is a Workspace.ws_id
	type has a value which is a Workspace.type_string
	perm has a value which is a Workspace.permission
	savedby has a value which is a reference to a list where each element is a Workspace.username
	meta has a value which is a Workspace.usermeta
	after has a value which is a Workspace.timestamp
	before has a value which is a Workspace.timestamp
	after_epoch has a value which is a Workspace.epoch
	before_epoch has a value which is a Workspace.epoch
	minObjectID has a value which is a Workspace.obj_id
	maxObjectID has a value which is a Workspace.obj_id
	showDeleted has a value which is a Workspace.boolean
	showOnlyDeleted has a value which is a Workspace.boolean
	showHidden has a value which is a Workspace.boolean
	showAllVersions has a value which is a Workspace.boolean
	includeMetadata has a value which is a Workspace.boolean
	excludeGlobal has a value which is a Workspace.boolean
	limit has a value which is an int
ws_name is a string
ws_id is an int
type_string is a string
permission is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
timestamp is a string
epoch is an int
obj_id is an int
boolean is an int
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
obj_name is a string


=end text

=item Description

List objects in one or more workspaces.

=back

=cut

 sub list_objects
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function list_objects (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to list_objects:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'list_objects');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.list_objects",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'list_objects',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method list_objects",
					    status_line => $self->{client}->status_line,
					    method_name => 'list_objects',
				       );
    }
}
 


=head2 get_objectmeta

  $metadata = $obj->get_objectmeta($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.get_objectmeta_params
$metadata is a Workspace.object_metadata
get_objectmeta_params is a reference to a hash where the following keys are defined:
	id has a value which is a Workspace.obj_name
	workspace has a value which is a Workspace.ws_name
	instance has a value which is an int
	auth has a value which is a string
obj_name is a string
ws_name is a string
object_metadata is a reference to a list containing 12 items:
	0: (id) a Workspace.obj_name
	1: (type) a Workspace.type_string
	2: (moddate) a Workspace.timestamp
	3: (instance) an int
	4: (command) a string
	5: (lastmodifier) a Workspace.username
	6: (owner) a Workspace.username
	7: (workspace) a Workspace.ws_name
	8: (ref) a string
	9: (chsum) a string
	10: (metadata) a Workspace.usermeta
	11: (objid) a Workspace.obj_id
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
obj_id is an int

</pre>

=end html

=begin text

$params is a Workspace.get_objectmeta_params
$metadata is a Workspace.object_metadata
get_objectmeta_params is a reference to a hash where the following keys are defined:
	id has a value which is a Workspace.obj_name
	workspace has a value which is a Workspace.ws_name
	instance has a value which is an int
	auth has a value which is a string
obj_name is a string
ws_name is a string
object_metadata is a reference to a list containing 12 items:
	0: (id) a Workspace.obj_name
	1: (type) a Workspace.type_string
	2: (moddate) a Workspace.timestamp
	3: (instance) an int
	4: (command) a string
	5: (lastmodifier) a Workspace.username
	6: (owner) a Workspace.username
	7: (workspace) a Workspace.ws_name
	8: (ref) a string
	9: (chsum) a string
	10: (metadata) a Workspace.usermeta
	11: (objid) a Workspace.obj_id
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string
obj_id is an int


=end text

=item Description

Retrieves the metadata for a specified object from the specified
workspace. Provides access to metadata for all versions of the object
via the instance parameter. Provided for backwards compatibility.

@deprecated Workspace.get_object_info3

=back

=cut

 sub get_objectmeta
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_objectmeta (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_objectmeta:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_objectmeta');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_objectmeta",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_objectmeta',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_objectmeta",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_objectmeta',
				       );
    }
}
 


=head2 get_object_info

  $info = $obj->get_object_info($object_ids, $includeMetadata)

=over 4

=item Parameter and return types

=begin html

<pre>
$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
$includeMetadata is a Workspace.boolean
$info is a reference to a list where each element is a Workspace.object_info
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
boolean is an int
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
$includeMetadata is a Workspace.boolean
$info is a reference to a list where each element is a Workspace.object_info
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
boolean is an int
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description

Get information about objects from the workspace.

Set includeMetadata true to include the user specified metadata.
Otherwise the metadata in the object_info will be null.

This method will be replaced by the behavior of get_object_info_new
in the future.

@deprecated Workspace.get_object_info3

=back

=cut

 sub get_object_info
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_object_info (received $n, expecting 2)");
    }
    {
	my($object_ids, $includeMetadata) = @args;

	my @_bad_arguments;
        (ref($object_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"object_ids\" (value was \"$object_ids\")");
        (!ref($includeMetadata)) or push(@_bad_arguments, "Invalid type for argument 2 \"includeMetadata\" (value was \"$includeMetadata\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_object_info:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_object_info');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_object_info",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_object_info',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_object_info",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_object_info',
				       );
    }
}
 


=head2 get_object_info_new

  $info = $obj->get_object_info_new($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.GetObjectInfoNewParams
$info is a reference to a list where each element is a Workspace.object_info
GetObjectInfoNewParams is a reference to a hash where the following keys are defined:
	objects has a value which is a reference to a list where each element is a Workspace.ObjectSpecification
	includeMetadata has a value which is a Workspace.boolean
	ignoreErrors has a value which is a Workspace.boolean
ObjectSpecification is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.ref_string
	obj_path has a value which is a Workspace.ref_chain
	obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
	to_obj_path has a value which is a Workspace.ref_chain
	to_obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
	find_reference_path has a value which is a Workspace.boolean
	included has a value which is a reference to a list where each element is a Workspace.object_path
	strict_maps has a value which is a Workspace.boolean
	strict_arrays has a value which is a Workspace.boolean
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
ref_string is a string
ref_chain is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
obj_ref is a string
boolean is an int
object_path is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$params is a Workspace.GetObjectInfoNewParams
$info is a reference to a list where each element is a Workspace.object_info
GetObjectInfoNewParams is a reference to a hash where the following keys are defined:
	objects has a value which is a reference to a list where each element is a Workspace.ObjectSpecification
	includeMetadata has a value which is a Workspace.boolean
	ignoreErrors has a value which is a Workspace.boolean
ObjectSpecification is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.ref_string
	obj_path has a value which is a Workspace.ref_chain
	obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
	to_obj_path has a value which is a Workspace.ref_chain
	to_obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
	find_reference_path has a value which is a Workspace.boolean
	included has a value which is a reference to a list where each element is a Workspace.object_path
	strict_maps has a value which is a Workspace.boolean
	strict_arrays has a value which is a Workspace.boolean
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
ref_string is a string
ref_chain is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
obj_ref is a string
boolean is an int
object_path is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description

Get information about objects from the workspace.

@deprecated Workspace.get_object_info3

=back

=cut

 sub get_object_info_new
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_object_info_new (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_object_info_new:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_object_info_new');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_object_info_new",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_object_info_new',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_object_info_new",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_object_info_new',
				       );
    }
}
 


=head2 get_object_info3

  $results = $obj->get_object_info3($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.GetObjectInfo3Params
$results is a Workspace.GetObjectInfo3Results
GetObjectInfo3Params is a reference to a hash where the following keys are defined:
	objects has a value which is a reference to a list where each element is a Workspace.ObjectSpecification
	includeMetadata has a value which is a Workspace.boolean
	ignoreErrors has a value which is a Workspace.boolean
ObjectSpecification is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.ref_string
	obj_path has a value which is a Workspace.ref_chain
	obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
	to_obj_path has a value which is a Workspace.ref_chain
	to_obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
	find_reference_path has a value which is a Workspace.boolean
	included has a value which is a reference to a list where each element is a Workspace.object_path
	strict_maps has a value which is a Workspace.boolean
	strict_arrays has a value which is a Workspace.boolean
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
ref_string is a string
ref_chain is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
obj_ref is a string
boolean is an int
object_path is a string
GetObjectInfo3Results is a reference to a hash where the following keys are defined:
	infos has a value which is a reference to a list where each element is a Workspace.object_info
	paths has a value which is a reference to a list where each element is a reference to a list where each element is a Workspace.obj_ref
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$params is a Workspace.GetObjectInfo3Params
$results is a Workspace.GetObjectInfo3Results
GetObjectInfo3Params is a reference to a hash where the following keys are defined:
	objects has a value which is a reference to a list where each element is a Workspace.ObjectSpecification
	includeMetadata has a value which is a Workspace.boolean
	ignoreErrors has a value which is a Workspace.boolean
ObjectSpecification is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.ref_string
	obj_path has a value which is a Workspace.ref_chain
	obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
	to_obj_path has a value which is a Workspace.ref_chain
	to_obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
	find_reference_path has a value which is a Workspace.boolean
	included has a value which is a reference to a list where each element is a Workspace.object_path
	strict_maps has a value which is a Workspace.boolean
	strict_arrays has a value which is a Workspace.boolean
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
ref_string is a string
ref_chain is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
obj_ref is a string
boolean is an int
object_path is a string
GetObjectInfo3Results is a reference to a hash where the following keys are defined:
	infos has a value which is a reference to a list where each element is a Workspace.object_info
	paths has a value which is a reference to a list where each element is a reference to a list where each element is a Workspace.obj_ref
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description



=back

=cut

 sub get_object_info3
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_object_info3 (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_object_info3:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_object_info3');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_object_info3",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_object_info3',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_object_info3",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_object_info3',
				       );
    }
}
 


=head2 rename_workspace

  $renamed = $obj->rename_workspace($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.RenameWorkspaceParams
$renamed is a Workspace.workspace_info
RenameWorkspaceParams is a reference to a hash where the following keys are defined:
	wsi has a value which is a Workspace.WorkspaceIdentity
	new_name has a value which is a Workspace.ws_name
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
workspace_info is a reference to a list containing 9 items:
	0: (id) a Workspace.ws_id
	1: (workspace) a Workspace.ws_name
	2: (owner) a Workspace.username
	3: (moddate) a Workspace.timestamp
	4: (max_objid) an int
	5: (user_permission) a Workspace.permission
	6: (globalread) a Workspace.permission
	7: (lockstat) a Workspace.lock_status
	8: (metadata) a Workspace.usermeta
username is a string
timestamp is a string
permission is a string
lock_status is a string
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$params is a Workspace.RenameWorkspaceParams
$renamed is a Workspace.workspace_info
RenameWorkspaceParams is a reference to a hash where the following keys are defined:
	wsi has a value which is a Workspace.WorkspaceIdentity
	new_name has a value which is a Workspace.ws_name
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
workspace_info is a reference to a list containing 9 items:
	0: (id) a Workspace.ws_id
	1: (workspace) a Workspace.ws_name
	2: (owner) a Workspace.username
	3: (moddate) a Workspace.timestamp
	4: (max_objid) an int
	5: (user_permission) a Workspace.permission
	6: (globalread) a Workspace.permission
	7: (lockstat) a Workspace.lock_status
	8: (metadata) a Workspace.usermeta
username is a string
timestamp is a string
permission is a string
lock_status is a string
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description

Rename a workspace.

=back

=cut

 sub rename_workspace
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function rename_workspace (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to rename_workspace:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'rename_workspace');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.rename_workspace",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'rename_workspace',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method rename_workspace",
					    status_line => $self->{client}->status_line,
					    method_name => 'rename_workspace',
				       );
    }
}
 


=head2 rename_object

  $renamed = $obj->rename_object($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.RenameObjectParams
$renamed is a Workspace.object_info
RenameObjectParams is a reference to a hash where the following keys are defined:
	obj has a value which is a Workspace.ObjectIdentity
	new_name has a value which is a Workspace.obj_name
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$params is a Workspace.RenameObjectParams
$renamed is a Workspace.object_info
RenameObjectParams is a reference to a hash where the following keys are defined:
	obj has a value which is a Workspace.ObjectIdentity
	new_name has a value which is a Workspace.obj_name
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description

Rename an object. User meta data is always returned as null.

=back

=cut

 sub rename_object
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function rename_object (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to rename_object:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'rename_object');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.rename_object",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'rename_object',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method rename_object",
					    status_line => $self->{client}->status_line,
					    method_name => 'rename_object',
				       );
    }
}
 


=head2 copy_object

  $copied = $obj->copy_object($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.CopyObjectParams
$copied is a Workspace.object_info
CopyObjectParams is a reference to a hash where the following keys are defined:
	from has a value which is a Workspace.ObjectIdentity
	to has a value which is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$params is a Workspace.CopyObjectParams
$copied is a Workspace.object_info
CopyObjectParams is a reference to a hash where the following keys are defined:
	from has a value which is a Workspace.ObjectIdentity
	to has a value which is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description

Copy an object. Returns the object_info for the newest version.

=back

=cut

 sub copy_object
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function copy_object (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to copy_object:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'copy_object');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.copy_object",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'copy_object',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method copy_object",
					    status_line => $self->{client}->status_line,
					    method_name => 'copy_object',
				       );
    }
}
 


=head2 revert_object

  $reverted = $obj->revert_object($object)

=over 4

=item Parameter and return types

=begin html

<pre>
$object is a Workspace.ObjectIdentity
$reverted is a Workspace.object_info
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string

</pre>

=end html

=begin text

$object is a Workspace.ObjectIdentity
$reverted is a Workspace.object_info
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string
object_info is a reference to a list containing 11 items:
	0: (objid) a Workspace.obj_id
	1: (name) a Workspace.obj_name
	2: (type) a Workspace.type_string
	3: (save_date) a Workspace.timestamp
	4: (version) an int
	5: (saved_by) a Workspace.username
	6: (wsid) a Workspace.ws_id
	7: (workspace) a Workspace.ws_name
	8: (chsum) a string
	9: (size) an int
	10: (meta) a Workspace.usermeta
type_string is a string
timestamp is a string
username is a string
usermeta is a reference to a hash where the key is a string and the value is a string


=end text

=item Description

Revert an object.

        The object specified in the ObjectIdentity is reverted to the version
        specified in the ObjectIdentity.

=back

=cut

 sub revert_object
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function revert_object (received $n, expecting 1)");
    }
    {
	my($object) = @args;

	my @_bad_arguments;
        (ref($object) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"object\" (value was \"$object\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to revert_object:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'revert_object');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.revert_object",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'revert_object',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method revert_object",
					    status_line => $self->{client}->status_line,
					    method_name => 'revert_object',
				       );
    }
}
 


=head2 get_names_by_prefix

  $res = $obj->get_names_by_prefix($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.GetNamesByPrefixParams
$res is a Workspace.GetNamesByPrefixResults
GetNamesByPrefixParams is a reference to a hash where the following keys are defined:
	workspaces has a value which is a reference to a list where each element is a Workspace.WorkspaceIdentity
	prefix has a value which is a string
	includeHidden has a value which is a Workspace.boolean
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
boolean is an int
GetNamesByPrefixResults is a reference to a hash where the following keys are defined:
	names has a value which is a reference to a list where each element is a reference to a list where each element is a Workspace.obj_name
obj_name is a string

</pre>

=end html

=begin text

$params is a Workspace.GetNamesByPrefixParams
$res is a Workspace.GetNamesByPrefixResults
GetNamesByPrefixParams is a reference to a hash where the following keys are defined:
	workspaces has a value which is a reference to a list where each element is a Workspace.WorkspaceIdentity
	prefix has a value which is a string
	includeHidden has a value which is a Workspace.boolean
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int
boolean is an int
GetNamesByPrefixResults is a reference to a hash where the following keys are defined:
	names has a value which is a reference to a list where each element is a reference to a list where each element is a Workspace.obj_name
obj_name is a string


=end text

=item Description

Get object names matching a prefix. At most 1000 names are returned.
No particular ordering is guaranteed, nor is which names will be
returned if more than 1000 are found.

This function is intended for use as an autocomplete helper function.

=back

=cut

 sub get_names_by_prefix
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_names_by_prefix (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_names_by_prefix:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_names_by_prefix');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_names_by_prefix",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_names_by_prefix',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_names_by_prefix",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_names_by_prefix',
				       );
    }
}
 


=head2 hide_objects

  $obj->hide_objects($object_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string

</pre>

=end html

=begin text

$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string


=end text

=item Description

Hide objects. All versions of an object are hidden, regardless of
the version specified in the ObjectIdentity. Hidden objects do not
appear in the list_objects method.

=back

=cut

 sub hide_objects
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function hide_objects (received $n, expecting 1)");
    }
    {
	my($object_ids) = @args;

	my @_bad_arguments;
        (ref($object_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"object_ids\" (value was \"$object_ids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to hide_objects:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'hide_objects');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.hide_objects",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'hide_objects',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method hide_objects",
					    status_line => $self->{client}->status_line,
					    method_name => 'hide_objects',
				       );
    }
}
 


=head2 unhide_objects

  $obj->unhide_objects($object_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string

</pre>

=end html

=begin text

$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string


=end text

=item Description

Unhide objects. All versions of an object are unhidden, regardless
of the version specified in the ObjectIdentity.

=back

=cut

 sub unhide_objects
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function unhide_objects (received $n, expecting 1)");
    }
    {
	my($object_ids) = @args;

	my @_bad_arguments;
        (ref($object_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"object_ids\" (value was \"$object_ids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to unhide_objects:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'unhide_objects');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.unhide_objects",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'unhide_objects',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method unhide_objects",
					    status_line => $self->{client}->status_line,
					    method_name => 'unhide_objects',
				       );
    }
}
 


=head2 delete_objects

  $obj->delete_objects($object_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string

</pre>

=end html

=begin text

$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string


=end text

=item Description

Delete objects. All versions of an object are deleted, regardless of
the version specified in the ObjectIdentity.

=back

=cut

 sub delete_objects
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function delete_objects (received $n, expecting 1)");
    }
    {
	my($object_ids) = @args;

	my @_bad_arguments;
        (ref($object_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"object_ids\" (value was \"$object_ids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to delete_objects:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'delete_objects');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.delete_objects",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'delete_objects',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method delete_objects",
					    status_line => $self->{client}->status_line,
					    method_name => 'delete_objects',
				       );
    }
}
 


=head2 undelete_objects

  $obj->undelete_objects($object_ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string

</pre>

=end html

=begin text

$object_ids is a reference to a list where each element is a Workspace.ObjectIdentity
ObjectIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	wsid has a value which is a Workspace.ws_id
	name has a value which is a Workspace.obj_name
	objid has a value which is a Workspace.obj_id
	ver has a value which is a Workspace.obj_ver
	ref has a value which is a Workspace.obj_ref
ws_name is a string
ws_id is an int
obj_name is a string
obj_id is an int
obj_ver is an int
obj_ref is a string


=end text

=item Description

Undelete objects. All versions of an object are undeleted, regardless
of the version specified in the ObjectIdentity. If an object is not
deleted, no error is thrown.

=back

=cut

 sub undelete_objects
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function undelete_objects (received $n, expecting 1)");
    }
    {
	my($object_ids) = @args;

	my @_bad_arguments;
        (ref($object_ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"object_ids\" (value was \"$object_ids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to undelete_objects:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'undelete_objects');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.undelete_objects",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'undelete_objects',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method undelete_objects",
					    status_line => $self->{client}->status_line,
					    method_name => 'undelete_objects',
				       );
    }
}
 


=head2 delete_workspace

  $obj->delete_workspace($wsi)

=over 4

=item Parameter and return types

=begin html

<pre>
$wsi is a Workspace.WorkspaceIdentity
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int

</pre>

=end html

=begin text

$wsi is a Workspace.WorkspaceIdentity
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int


=end text

=item Description

Delete a workspace. All objects contained in the workspace are deleted.

=back

=cut

 sub delete_workspace
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function delete_workspace (received $n, expecting 1)");
    }
    {
	my($wsi) = @args;

	my @_bad_arguments;
        (ref($wsi) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"wsi\" (value was \"$wsi\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to delete_workspace:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'delete_workspace');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.delete_workspace",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'delete_workspace',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method delete_workspace",
					    status_line => $self->{client}->status_line,
					    method_name => 'delete_workspace',
				       );
    }
}
 


=head2 undelete_workspace

  $obj->undelete_workspace($wsi)

=over 4

=item Parameter and return types

=begin html

<pre>
$wsi is a Workspace.WorkspaceIdentity
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int

</pre>

=end html

=begin text

$wsi is a Workspace.WorkspaceIdentity
WorkspaceIdentity is a reference to a hash where the following keys are defined:
	workspace has a value which is a Workspace.ws_name
	id has a value which is a Workspace.ws_id
ws_name is a string
ws_id is an int


=end text

=item Description

Undelete a workspace. All objects contained in the workspace are
undeleted, regardless of their state at the time the workspace was
deleted.

=back

=cut

 sub undelete_workspace
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function undelete_workspace (received $n, expecting 1)");
    }
    {
	my($wsi) = @args;

	my @_bad_arguments;
        (ref($wsi) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"wsi\" (value was \"$wsi\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to undelete_workspace:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'undelete_workspace');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.undelete_workspace",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'undelete_workspace',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method undelete_workspace",
					    status_line => $self->{client}->status_line,
					    method_name => 'undelete_workspace',
				       );
    }
}
 


=head2 request_module_ownership

  $obj->request_module_ownership($mod)

=over 4

=item Parameter and return types

=begin html

<pre>
$mod is a Workspace.modulename
modulename is a string

</pre>

=end html

=begin text

$mod is a Workspace.modulename
modulename is a string


=end text

=item Description

Request ownership of a module name. A Workspace administrator
must approve the request.

=back

=cut

 sub request_module_ownership
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function request_module_ownership (received $n, expecting 1)");
    }
    {
	my($mod) = @args;

	my @_bad_arguments;
        (!ref($mod)) or push(@_bad_arguments, "Invalid type for argument 1 \"mod\" (value was \"$mod\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to request_module_ownership:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'request_module_ownership');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.request_module_ownership",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'request_module_ownership',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method request_module_ownership",
					    status_line => $self->{client}->status_line,
					    method_name => 'request_module_ownership',
				       );
    }
}
 


=head2 register_typespec

  $return = $obj->register_typespec($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.RegisterTypespecParams
$return is a reference to a hash where the key is a Workspace.type_string and the value is a Workspace.jsonschema
RegisterTypespecParams is a reference to a hash where the following keys are defined:
	spec has a value which is a Workspace.typespec
	mod has a value which is a Workspace.modulename
	new_types has a value which is a reference to a list where each element is a Workspace.typename
	remove_types has a value which is a reference to a list where each element is a Workspace.typename
	dependencies has a value which is a reference to a hash where the key is a Workspace.modulename and the value is a Workspace.spec_version
	dryrun has a value which is a Workspace.boolean
	prev_ver has a value which is a Workspace.spec_version
typespec is a string
modulename is a string
typename is a string
spec_version is an int
boolean is an int
type_string is a string
jsonschema is a string

</pre>

=end html

=begin text

$params is a Workspace.RegisterTypespecParams
$return is a reference to a hash where the key is a Workspace.type_string and the value is a Workspace.jsonschema
RegisterTypespecParams is a reference to a hash where the following keys are defined:
	spec has a value which is a Workspace.typespec
	mod has a value which is a Workspace.modulename
	new_types has a value which is a reference to a list where each element is a Workspace.typename
	remove_types has a value which is a reference to a list where each element is a Workspace.typename
	dependencies has a value which is a reference to a hash where the key is a Workspace.modulename and the value is a Workspace.spec_version
	dryrun has a value which is a Workspace.boolean
	prev_ver has a value which is a Workspace.spec_version
typespec is a string
modulename is a string
typename is a string
spec_version is an int
boolean is an int
type_string is a string
jsonschema is a string


=end text

=item Description

Register a new typespec or recompile a previously registered typespec
with new options.
See the documentation of RegisterTypespecParams for more details.
Also see the release_types function.

=back

=cut

 sub register_typespec
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function register_typespec (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to register_typespec:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'register_typespec');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.register_typespec",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'register_typespec',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method register_typespec",
					    status_line => $self->{client}->status_line,
					    method_name => 'register_typespec',
				       );
    }
}
 


=head2 register_typespec_copy

  $new_local_version = $obj->register_typespec_copy($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.RegisterTypespecCopyParams
$new_local_version is a Workspace.spec_version
RegisterTypespecCopyParams is a reference to a hash where the following keys are defined:
	external_workspace_url has a value which is a string
	mod has a value which is a Workspace.modulename
	version has a value which is a Workspace.spec_version
modulename is a string
spec_version is an int

</pre>

=end html

=begin text

$params is a Workspace.RegisterTypespecCopyParams
$new_local_version is a Workspace.spec_version
RegisterTypespecCopyParams is a reference to a hash where the following keys are defined:
	external_workspace_url has a value which is a string
	mod has a value which is a Workspace.modulename
	version has a value which is a Workspace.spec_version
modulename is a string
spec_version is an int


=end text

=item Description

Register a copy of new typespec or refresh an existing typespec which is
loaded from another workspace for synchronization. Method returns new
version of module in current workspace.

Also see the release_types function.

=back

=cut

 sub register_typespec_copy
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function register_typespec_copy (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to register_typespec_copy:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'register_typespec_copy');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.register_typespec_copy",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'register_typespec_copy',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method register_typespec_copy",
					    status_line => $self->{client}->status_line,
					    method_name => 'register_typespec_copy',
				       );
    }
}
 


=head2 release_module

  $types = $obj->release_module($mod)

=over 4

=item Parameter and return types

=begin html

<pre>
$mod is a Workspace.modulename
$types is a reference to a list where each element is a Workspace.type_string
modulename is a string
type_string is a string

</pre>

=end html

=begin text

$mod is a Workspace.modulename
$types is a reference to a list where each element is a Workspace.type_string
modulename is a string
type_string is a string


=end text

=item Description

Release a module for general use of its types.

Releases the most recent version of a module. Releasing a module does
two things to the module's types:
1) If a type's major version is 0, it is changed to 1. A major
        version of 0 implies that the type is in development and may have
        backwards incompatible changes from minor version to minor version.
        Once a type is released, backwards incompatible changes always
        cause a major version increment.
2) This version of the type becomes the default version, and if a 
        specific version is not supplied in a function call, this version
        will be used. This means that newer, unreleased versions of the
        type may be skipped.

=back

=cut

 sub release_module
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function release_module (received $n, expecting 1)");
    }
    {
	my($mod) = @args;

	my @_bad_arguments;
        (!ref($mod)) or push(@_bad_arguments, "Invalid type for argument 1 \"mod\" (value was \"$mod\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to release_module:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'release_module');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.release_module",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'release_module',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method release_module",
					    status_line => $self->{client}->status_line,
					    method_name => 'release_module',
				       );
    }
}
 


=head2 list_modules

  $modules = $obj->list_modules($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.ListModulesParams
$modules is a reference to a list where each element is a Workspace.modulename
ListModulesParams is a reference to a hash where the following keys are defined:
	owner has a value which is a Workspace.username
username is a string
modulename is a string

</pre>

=end html

=begin text

$params is a Workspace.ListModulesParams
$modules is a reference to a list where each element is a Workspace.modulename
ListModulesParams is a reference to a hash where the following keys are defined:
	owner has a value which is a Workspace.username
username is a string
modulename is a string


=end text

=item Description

List typespec modules.

=back

=cut

 sub list_modules
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function list_modules (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to list_modules:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'list_modules');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.list_modules",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'list_modules',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method list_modules",
					    status_line => $self->{client}->status_line,
					    method_name => 'list_modules',
				       );
    }
}
 


=head2 list_module_versions

  $vers = $obj->list_module_versions($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.ListModuleVersionsParams
$vers is a Workspace.ModuleVersions
ListModuleVersionsParams is a reference to a hash where the following keys are defined:
	mod has a value which is a Workspace.modulename
	type has a value which is a Workspace.type_string
modulename is a string
type_string is a string
ModuleVersions is a reference to a hash where the following keys are defined:
	mod has a value which is a Workspace.modulename
	vers has a value which is a reference to a list where each element is a Workspace.spec_version
	released_vers has a value which is a reference to a list where each element is a Workspace.spec_version
spec_version is an int

</pre>

=end html

=begin text

$params is a Workspace.ListModuleVersionsParams
$vers is a Workspace.ModuleVersions
ListModuleVersionsParams is a reference to a hash where the following keys are defined:
	mod has a value which is a Workspace.modulename
	type has a value which is a Workspace.type_string
modulename is a string
type_string is a string
ModuleVersions is a reference to a hash where the following keys are defined:
	mod has a value which is a Workspace.modulename
	vers has a value which is a reference to a list where each element is a Workspace.spec_version
	released_vers has a value which is a reference to a list where each element is a Workspace.spec_version
spec_version is an int


=end text

=item Description

List typespec module versions.

=back

=cut

 sub list_module_versions
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function list_module_versions (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to list_module_versions:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'list_module_versions');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.list_module_versions",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'list_module_versions',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method list_module_versions",
					    status_line => $self->{client}->status_line,
					    method_name => 'list_module_versions',
				       );
    }
}
 


=head2 get_module_info

  $info = $obj->get_module_info($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.GetModuleInfoParams
$info is a Workspace.ModuleInfo
GetModuleInfoParams is a reference to a hash where the following keys are defined:
	mod has a value which is a Workspace.modulename
	ver has a value which is a Workspace.spec_version
modulename is a string
spec_version is an int
ModuleInfo is a reference to a hash where the following keys are defined:
	owners has a value which is a reference to a list where each element is a Workspace.username
	ver has a value which is a Workspace.spec_version
	spec has a value which is a Workspace.typespec
	description has a value which is a string
	types has a value which is a reference to a hash where the key is a Workspace.type_string and the value is a Workspace.jsonschema
	included_spec_version has a value which is a reference to a hash where the key is a Workspace.modulename and the value is a Workspace.spec_version
	chsum has a value which is a string
	functions has a value which is a reference to a list where each element is a Workspace.func_string
	is_released has a value which is a Workspace.boolean
username is a string
typespec is a string
type_string is a string
jsonschema is a string
func_string is a string
boolean is an int

</pre>

=end html

=begin text

$params is a Workspace.GetModuleInfoParams
$info is a Workspace.ModuleInfo
GetModuleInfoParams is a reference to a hash where the following keys are defined:
	mod has a value which is a Workspace.modulename
	ver has a value which is a Workspace.spec_version
modulename is a string
spec_version is an int
ModuleInfo is a reference to a hash where the following keys are defined:
	owners has a value which is a reference to a list where each element is a Workspace.username
	ver has a value which is a Workspace.spec_version
	spec has a value which is a Workspace.typespec
	description has a value which is a string
	types has a value which is a reference to a hash where the key is a Workspace.type_string and the value is a Workspace.jsonschema
	included_spec_version has a value which is a reference to a hash where the key is a Workspace.modulename and the value is a Workspace.spec_version
	chsum has a value which is a string
	functions has a value which is a reference to a list where each element is a Workspace.func_string
	is_released has a value which is a Workspace.boolean
username is a string
typespec is a string
type_string is a string
jsonschema is a string
func_string is a string
boolean is an int


=end text

=item Description



=back

=cut

 sub get_module_info
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_module_info (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_module_info:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_module_info');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_module_info",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_module_info',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_module_info",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_module_info',
				       );
    }
}
 


=head2 get_jsonschema

  $schema = $obj->get_jsonschema($type)

=over 4

=item Parameter and return types

=begin html

<pre>
$type is a Workspace.type_string
$schema is a Workspace.jsonschema
type_string is a string
jsonschema is a string

</pre>

=end html

=begin text

$type is a Workspace.type_string
$schema is a Workspace.jsonschema
type_string is a string
jsonschema is a string


=end text

=item Description

Get JSON schema for a type.

=back

=cut

 sub get_jsonschema
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_jsonschema (received $n, expecting 1)");
    }
    {
	my($type) = @args;

	my @_bad_arguments;
        (!ref($type)) or push(@_bad_arguments, "Invalid type for argument 1 \"type\" (value was \"$type\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_jsonschema:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_jsonschema');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_jsonschema",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_jsonschema',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_jsonschema",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_jsonschema',
				       );
    }
}
 


=head2 translate_from_MD5_types

  $sem_types = $obj->translate_from_MD5_types($md5_types)

=over 4

=item Parameter and return types

=begin html

<pre>
$md5_types is a reference to a list where each element is a Workspace.type_string
$sem_types is a reference to a hash where the key is a Workspace.type_string and the value is a reference to a list where each element is a Workspace.type_string
type_string is a string

</pre>

=end html

=begin text

$md5_types is a reference to a list where each element is a Workspace.type_string
$sem_types is a reference to a hash where the key is a Workspace.type_string and the value is a reference to a list where each element is a Workspace.type_string
type_string is a string


=end text

=item Description

Translation from types qualified with MD5 to their semantic versions

=back

=cut

 sub translate_from_MD5_types
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function translate_from_MD5_types (received $n, expecting 1)");
    }
    {
	my($md5_types) = @args;

	my @_bad_arguments;
        (ref($md5_types) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"md5_types\" (value was \"$md5_types\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to translate_from_MD5_types:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'translate_from_MD5_types');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.translate_from_MD5_types",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'translate_from_MD5_types',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method translate_from_MD5_types",
					    status_line => $self->{client}->status_line,
					    method_name => 'translate_from_MD5_types',
				       );
    }
}
 


=head2 translate_to_MD5_types

  $md5_types = $obj->translate_to_MD5_types($sem_types)

=over 4

=item Parameter and return types

=begin html

<pre>
$sem_types is a reference to a list where each element is a Workspace.type_string
$md5_types is a reference to a hash where the key is a Workspace.type_string and the value is a Workspace.type_string
type_string is a string

</pre>

=end html

=begin text

$sem_types is a reference to a list where each element is a Workspace.type_string
$md5_types is a reference to a hash where the key is a Workspace.type_string and the value is a Workspace.type_string
type_string is a string


=end text

=item Description

Translation from types qualified with semantic versions to their MD5'ed versions

=back

=cut

 sub translate_to_MD5_types
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function translate_to_MD5_types (received $n, expecting 1)");
    }
    {
	my($sem_types) = @args;

	my @_bad_arguments;
        (ref($sem_types) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"sem_types\" (value was \"$sem_types\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to translate_to_MD5_types:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'translate_to_MD5_types');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.translate_to_MD5_types",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'translate_to_MD5_types',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method translate_to_MD5_types",
					    status_line => $self->{client}->status_line,
					    method_name => 'translate_to_MD5_types',
				       );
    }
}
 


=head2 get_type_info

  $info = $obj->get_type_info($type)

=over 4

=item Parameter and return types

=begin html

<pre>
$type is a Workspace.type_string
$info is a Workspace.TypeInfo
type_string is a string
TypeInfo is a reference to a hash where the following keys are defined:
	type_def has a value which is a Workspace.type_string
	description has a value which is a string
	spec_def has a value which is a string
	json_schema has a value which is a Workspace.jsonschema
	parsing_structure has a value which is a string
	module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	released_module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	type_vers has a value which is a reference to a list where each element is a Workspace.type_string
	released_type_vers has a value which is a reference to a list where each element is a Workspace.type_string
	using_func_defs has a value which is a reference to a list where each element is a Workspace.func_string
	using_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
	used_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
jsonschema is a string
spec_version is an int
func_string is a string

</pre>

=end html

=begin text

$type is a Workspace.type_string
$info is a Workspace.TypeInfo
type_string is a string
TypeInfo is a reference to a hash where the following keys are defined:
	type_def has a value which is a Workspace.type_string
	description has a value which is a string
	spec_def has a value which is a string
	json_schema has a value which is a Workspace.jsonschema
	parsing_structure has a value which is a string
	module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	released_module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	type_vers has a value which is a reference to a list where each element is a Workspace.type_string
	released_type_vers has a value which is a reference to a list where each element is a Workspace.type_string
	using_func_defs has a value which is a reference to a list where each element is a Workspace.func_string
	using_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
	used_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
jsonschema is a string
spec_version is an int
func_string is a string


=end text

=item Description



=back

=cut

 sub get_type_info
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_type_info (received $n, expecting 1)");
    }
    {
	my($type) = @args;

	my @_bad_arguments;
        (!ref($type)) or push(@_bad_arguments, "Invalid type for argument 1 \"type\" (value was \"$type\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_type_info:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_type_info');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_type_info",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_type_info',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_type_info",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_type_info',
				       );
    }
}
 


=head2 get_all_type_info

  $return = $obj->get_all_type_info($mod)

=over 4

=item Parameter and return types

=begin html

<pre>
$mod is a Workspace.modulename
$return is a reference to a list where each element is a Workspace.TypeInfo
modulename is a string
TypeInfo is a reference to a hash where the following keys are defined:
	type_def has a value which is a Workspace.type_string
	description has a value which is a string
	spec_def has a value which is a string
	json_schema has a value which is a Workspace.jsonschema
	parsing_structure has a value which is a string
	module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	released_module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	type_vers has a value which is a reference to a list where each element is a Workspace.type_string
	released_type_vers has a value which is a reference to a list where each element is a Workspace.type_string
	using_func_defs has a value which is a reference to a list where each element is a Workspace.func_string
	using_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
	used_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
type_string is a string
jsonschema is a string
spec_version is an int
func_string is a string

</pre>

=end html

=begin text

$mod is a Workspace.modulename
$return is a reference to a list where each element is a Workspace.TypeInfo
modulename is a string
TypeInfo is a reference to a hash where the following keys are defined:
	type_def has a value which is a Workspace.type_string
	description has a value which is a string
	spec_def has a value which is a string
	json_schema has a value which is a Workspace.jsonschema
	parsing_structure has a value which is a string
	module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	released_module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	type_vers has a value which is a reference to a list where each element is a Workspace.type_string
	released_type_vers has a value which is a reference to a list where each element is a Workspace.type_string
	using_func_defs has a value which is a reference to a list where each element is a Workspace.func_string
	using_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
	used_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
type_string is a string
jsonschema is a string
spec_version is an int
func_string is a string


=end text

=item Description



=back

=cut

 sub get_all_type_info
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_all_type_info (received $n, expecting 1)");
    }
    {
	my($mod) = @args;

	my @_bad_arguments;
        (!ref($mod)) or push(@_bad_arguments, "Invalid type for argument 1 \"mod\" (value was \"$mod\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_all_type_info:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_all_type_info');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_all_type_info",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_all_type_info',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_all_type_info",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_all_type_info',
				       );
    }
}
 


=head2 get_func_info

  $info = $obj->get_func_info($func)

=over 4

=item Parameter and return types

=begin html

<pre>
$func is a Workspace.func_string
$info is a Workspace.FuncInfo
func_string is a string
FuncInfo is a reference to a hash where the following keys are defined:
	func_def has a value which is a Workspace.func_string
	description has a value which is a string
	spec_def has a value which is a string
	parsing_structure has a value which is a string
	module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	released_module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	func_vers has a value which is a reference to a list where each element is a Workspace.func_string
	released_func_vers has a value which is a reference to a list where each element is a Workspace.func_string
	used_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
spec_version is an int
type_string is a string

</pre>

=end html

=begin text

$func is a Workspace.func_string
$info is a Workspace.FuncInfo
func_string is a string
FuncInfo is a reference to a hash where the following keys are defined:
	func_def has a value which is a Workspace.func_string
	description has a value which is a string
	spec_def has a value which is a string
	parsing_structure has a value which is a string
	module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	released_module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	func_vers has a value which is a reference to a list where each element is a Workspace.func_string
	released_func_vers has a value which is a reference to a list where each element is a Workspace.func_string
	used_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
spec_version is an int
type_string is a string


=end text

=item Description



=back

=cut

 sub get_func_info
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_func_info (received $n, expecting 1)");
    }
    {
	my($func) = @args;

	my @_bad_arguments;
        (!ref($func)) or push(@_bad_arguments, "Invalid type for argument 1 \"func\" (value was \"$func\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_func_info:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_func_info');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_func_info",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_func_info',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_func_info",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_func_info',
				       );
    }
}
 


=head2 get_all_func_info

  $info = $obj->get_all_func_info($mod)

=over 4

=item Parameter and return types

=begin html

<pre>
$mod is a Workspace.modulename
$info is a reference to a list where each element is a Workspace.FuncInfo
modulename is a string
FuncInfo is a reference to a hash where the following keys are defined:
	func_def has a value which is a Workspace.func_string
	description has a value which is a string
	spec_def has a value which is a string
	parsing_structure has a value which is a string
	module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	released_module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	func_vers has a value which is a reference to a list where each element is a Workspace.func_string
	released_func_vers has a value which is a reference to a list where each element is a Workspace.func_string
	used_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
func_string is a string
spec_version is an int
type_string is a string

</pre>

=end html

=begin text

$mod is a Workspace.modulename
$info is a reference to a list where each element is a Workspace.FuncInfo
modulename is a string
FuncInfo is a reference to a hash where the following keys are defined:
	func_def has a value which is a Workspace.func_string
	description has a value which is a string
	spec_def has a value which is a string
	parsing_structure has a value which is a string
	module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	released_module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
	func_vers has a value which is a reference to a list where each element is a Workspace.func_string
	released_func_vers has a value which is a reference to a list where each element is a Workspace.func_string
	used_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
func_string is a string
spec_version is an int
type_string is a string


=end text

=item Description



=back

=cut

 sub get_all_func_info
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function get_all_func_info (received $n, expecting 1)");
    }
    {
	my($mod) = @args;

	my @_bad_arguments;
        (!ref($mod)) or push(@_bad_arguments, "Invalid type for argument 1 \"mod\" (value was \"$mod\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to get_all_func_info:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'get_all_func_info');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.get_all_func_info",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'get_all_func_info',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method get_all_func_info",
					    status_line => $self->{client}->status_line,
					    method_name => 'get_all_func_info',
				       );
    }
}
 


=head2 grant_module_ownership

  $obj->grant_module_ownership($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.GrantModuleOwnershipParams
GrantModuleOwnershipParams is a reference to a hash where the following keys are defined:
	mod has a value which is a Workspace.modulename
	new_owner has a value which is a Workspace.username
	with_grant_option has a value which is a Workspace.boolean
modulename is a string
username is a string
boolean is an int

</pre>

=end html

=begin text

$params is a Workspace.GrantModuleOwnershipParams
GrantModuleOwnershipParams is a reference to a hash where the following keys are defined:
	mod has a value which is a Workspace.modulename
	new_owner has a value which is a Workspace.username
	with_grant_option has a value which is a Workspace.boolean
modulename is a string
username is a string
boolean is an int


=end text

=item Description

Grant ownership of a module. You must have grant ability on the
module.

=back

=cut

 sub grant_module_ownership
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function grant_module_ownership (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to grant_module_ownership:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'grant_module_ownership');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.grant_module_ownership",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'grant_module_ownership',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method grant_module_ownership",
					    status_line => $self->{client}->status_line,
					    method_name => 'grant_module_ownership',
				       );
    }
}
 


=head2 remove_module_ownership

  $obj->remove_module_ownership($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.RemoveModuleOwnershipParams
RemoveModuleOwnershipParams is a reference to a hash where the following keys are defined:
	mod has a value which is a Workspace.modulename
	old_owner has a value which is a Workspace.username
modulename is a string
username is a string

</pre>

=end html

=begin text

$params is a Workspace.RemoveModuleOwnershipParams
RemoveModuleOwnershipParams is a reference to a hash where the following keys are defined:
	mod has a value which is a Workspace.modulename
	old_owner has a value which is a Workspace.username
modulename is a string
username is a string


=end text

=item Description

Remove ownership from a current owner. You must have the grant ability
on the module.

=back

=cut

 sub remove_module_ownership
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function remove_module_ownership (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to remove_module_ownership:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'remove_module_ownership');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.remove_module_ownership",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'remove_module_ownership',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method remove_module_ownership",
					    status_line => $self->{client}->status_line,
					    method_name => 'remove_module_ownership',
				       );
    }
}
 


=head2 list_all_types

  $return = $obj->list_all_types($params)

=over 4

=item Parameter and return types

=begin html

<pre>
$params is a Workspace.ListAllTypesParams
$return is a reference to a hash where the key is a Workspace.modulename and the value is a reference to a hash where the key is a Workspace.typename and the value is a Workspace.typever
ListAllTypesParams is a reference to a hash where the following keys are defined:
	with_empty_modules has a value which is a Workspace.boolean
boolean is an int
modulename is a string
typename is a string
typever is a string

</pre>

=end html

=begin text

$params is a Workspace.ListAllTypesParams
$return is a reference to a hash where the key is a Workspace.modulename and the value is a reference to a hash where the key is a Workspace.typename and the value is a Workspace.typever
ListAllTypesParams is a reference to a hash where the following keys are defined:
	with_empty_modules has a value which is a Workspace.boolean
boolean is an int
modulename is a string
typename is a string
typever is a string


=end text

=item Description

List all released types with released version from all modules. Return
mapping from module name to mapping from type name to released type
version.

=back

=cut

 sub list_all_types
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function list_all_types (received $n, expecting 1)");
    }
    {
	my($params) = @args;

	my @_bad_arguments;
        (ref($params) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"params\" (value was \"$params\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to list_all_types:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'list_all_types');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.list_all_types",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'list_all_types',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method list_all_types",
					    status_line => $self->{client}->status_line,
					    method_name => 'list_all_types',
				       );
    }
}
 


=head2 administer

  $response = $obj->administer($command)

=over 4

=item Parameter and return types

=begin html

<pre>
$command is an UnspecifiedObject, which can hold any non-null object
$response is an UnspecifiedObject, which can hold any non-null object

</pre>

=end html

=begin text

$command is an UnspecifiedObject, which can hold any non-null object
$response is an UnspecifiedObject, which can hold any non-null object


=end text

=item Description

The administration interface.

=back

=cut

 sub administer
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function administer (received $n, expecting 1)");
    }
    {
	my($command) = @args;

	my @_bad_arguments;
        (defined $command) or push(@_bad_arguments, "Invalid type for argument 1 \"command\" (value was \"$command\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to administer:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'administer');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "Workspace.administer",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'administer',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method administer",
					    status_line => $self->{client}->status_line,
					    method_name => 'administer',
				       );
    }
}
 
  
sub status
{
    my($self, @args) = @_;
    if ((my $n = @args) != 0) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function status (received $n, expecting 0)");
    }
    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
        method => "Workspace.status",
        params => \@args,
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => 'status',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
                          );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method status",
                        status_line => $self->{client}->status_line,
                        method_name => 'status',
                       );
    }
}
   

sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "Workspace.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'administer',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method administer",
            status_line => $self->{client}->status_line,
            method_name => 'administer',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for Workspace::WorkspaceClient\n";
    }
    if ($sMajor == 0) {
        warn "Workspace::WorkspaceClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 boolean

=over 4



=item Description

A boolean. 0 = false, other = true.


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 ws_id

=over 4



=item Description

The unique, permanent numerical ID of a workspace.


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 ws_name

=over 4



=item Description

A string used as a name for a workspace.
Any string consisting of alphanumeric characters and "_", ".", or "-"
that is not an integer is acceptable. The name may optionally be
prefixed with the workspace owner's user name and a colon, e.g.
kbasetest:my_workspace.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 permission

=over 4



=item Description

Represents the permissions a user or users have to a workspace:

        'a' - administrator. All operations allowed.
        'w' - read/write.
        'r' - read.
        'n' - no permissions.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 username

=over 4



=item Description

Login name of a KBase user account.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 timestamp

=over 4



=item Description

A time in the format YYYY-MM-DDThh:mm:ssZ, where Z is either the
character Z (representing the UTC timezone) or the difference
in time to UTC in the format +/-HHMM, eg:
        2012-12-17T23:24:06-0500 (EST time)
        2013-04-03T08:56:32+0000 (UTC time)
        2013-04-03T08:56:32Z (UTC time)


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 epoch

=over 4



=item Description

A Unix epoch (the time since 00:00:00 1/1/1970 UTC) in milliseconds.


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 type_string

=over 4



=item Description

A type string.
Specifies the type and its version in a single string in the format
[module].[typename]-[major].[minor]:

module - a string. The module name of the typespec containing the type.
typename - a string. The name of the type as assigned by the typedef
        statement.
major - an integer. The major version of the type. A change in the
        major version implies the type has changed in a non-backwards
        compatible way.
minor - an integer. The minor version of the type. A change in the
        minor version implies that the type has changed in a way that is
        backwards compatible with previous type definitions.

In many cases, the major and minor versions are optional, and if not
provided the most recent version will be used.

Example: MyModule.MyType-3.1


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 id_type

=over 4



=item Description

An id type (e.g. from a typespec @id annotation: @id [idtype])


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 extracted_id

=over 4



=item Description

An id extracted from an object.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 usermeta

=over 4



=item Description

User provided metadata about an object.
Arbitrary key-value pairs provided by the user.


=item Definition

=begin html

<pre>
a reference to a hash where the key is a string and the value is a string
</pre>

=end html

=begin text

a reference to a hash where the key is a string and the value is a string

=end text

=back



=head2 lock_status

=over 4



=item Description

The lock status of a workspace.
One of 'unlocked', 'locked', or 'published'.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 WorkspaceIdentity

=over 4



=item Description

A workspace identifier.

                Select a workspace by one, and only one, of the numerical id or name.
                ws_id id - the numerical ID of the workspace.
                ws_name workspace - the name of the workspace.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
id has a value which is a Workspace.ws_id

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
id has a value which is a Workspace.ws_id


=end text

=back



=head2 workspace_metadata

=over 4



=item Description

Meta data associated with a workspace. Provided for backwards
compatibility. To be replaced by workspace_info.
        
ws_name id - name of the workspace 
username owner - name of the user who owns (who created) this workspace
timestamp moddate - date when the workspace was last modified
int objects - the approximate number of objects currently stored in
        the workspace.
permission user_permission - permissions for the currently logged in
        user for the workspace
permission global_permission - default permissions for the workspace
        for all KBase users
ws_id num_id - numerical ID of the workspace

@deprecated Workspace.workspace_info


=item Definition

=begin html

<pre>
a reference to a list containing 7 items:
0: (id) a Workspace.ws_name
1: (owner) a Workspace.username
2: (moddate) a Workspace.timestamp
3: (objects) an int
4: (user_permission) a Workspace.permission
5: (global_permission) a Workspace.permission
6: (num_id) a Workspace.ws_id

</pre>

=end html

=begin text

a reference to a list containing 7 items:
0: (id) a Workspace.ws_name
1: (owner) a Workspace.username
2: (moddate) a Workspace.timestamp
3: (objects) an int
4: (user_permission) a Workspace.permission
5: (global_permission) a Workspace.permission
6: (num_id) a Workspace.ws_id


=end text

=back



=head2 workspace_info

=over 4



=item Description

Information about a workspace.

        ws_id id - the numerical ID of the workspace.
        ws_name workspace - name of the workspace.
        username owner - name of the user who owns (e.g. created) this workspace.
        timestamp moddate - date when the workspace was last modified.
        int max_objid - the maximum object ID appearing in this workspace.
                Since cloning a workspace preserves object IDs, this number may be
                greater than the number of objects in a newly cloned workspace.
        permission user_permission - permissions for the authenticated user of
                this workspace.
        permission globalread - whether this workspace is globally readable.
        lock_status lockstat - the status of the workspace lock.
        usermeta metadata - arbitrary user-supplied metadata about
                the workspace.


=item Definition

=begin html

<pre>
a reference to a list containing 9 items:
0: (id) a Workspace.ws_id
1: (workspace) a Workspace.ws_name
2: (owner) a Workspace.username
3: (moddate) a Workspace.timestamp
4: (max_objid) an int
5: (user_permission) a Workspace.permission
6: (globalread) a Workspace.permission
7: (lockstat) a Workspace.lock_status
8: (metadata) a Workspace.usermeta

</pre>

=end html

=begin text

a reference to a list containing 9 items:
0: (id) a Workspace.ws_id
1: (workspace) a Workspace.ws_name
2: (owner) a Workspace.username
3: (moddate) a Workspace.timestamp
4: (max_objid) an int
5: (user_permission) a Workspace.permission
6: (globalread) a Workspace.permission
7: (lockstat) a Workspace.lock_status
8: (metadata) a Workspace.usermeta


=end text

=back



=head2 obj_id

=over 4



=item Description

The unique, permanent numerical ID of an object.


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 obj_name

=over 4



=item Description

A string used as a name for an object.
Any string consisting of alphanumeric characters and the characters
        |._- that is not an integer is acceptable.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 obj_ver

=over 4



=item Description

An object version.
The version of the object, starting at 1.


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 obj_ref

=over 4



=item Description

A string that uniquely identifies an object in the workspace service.

        The format is [ws_name or id]/[obj_name or id]/[obj_ver].
        For example, MyFirstWorkspace/MyFirstObject/3 would identify the third version
        of an object called MyFirstObject in the workspace called
        MyFirstWorkspace. 42/Panic/1 would identify the first version of
        the object name Panic in workspace with id 42. Towel/1/6 would
        identify the 6th version of the object with id 1 in the Towel
        workspace.If the version number is omitted, the latest version of
        the object is assumed.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 ObjectIdentity

=over 4



=item Description

An object identifier.

Select an object by either:
        One, and only one, of the numerical id or name of the workspace.
                ws_id wsid - the numerical ID of the workspace.
                ws_name workspace - the name of the workspace.
        AND 
        One, and only one, of the numerical id or name of the object.
                obj_id objid- the numerical ID of the object.
                obj_name name - name of the object.
        OPTIONALLY
                obj_ver ver - the version of the object.
OR an object reference string:
        obj_ref ref - an object reference string.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
wsid has a value which is a Workspace.ws_id
name has a value which is a Workspace.obj_name
objid has a value which is a Workspace.obj_id
ver has a value which is a Workspace.obj_ver
ref has a value which is a Workspace.obj_ref

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
wsid has a value which is a Workspace.ws_id
name has a value which is a Workspace.obj_name
objid has a value which is a Workspace.obj_id
ver has a value which is a Workspace.obj_ver
ref has a value which is a Workspace.obj_ref


=end text

=back



=head2 ref_chain

=over 4



=item Description

A chain of objects with references to one another.

        An object reference chain consists of a list of objects where the nth
        object possesses a reference, either in the object itself or in the
        object provenance, to the n+1th object.


=item Definition

=begin html

<pre>
a reference to a list where each element is a Workspace.ObjectIdentity
</pre>

=end html

=begin text

a reference to a list where each element is a Workspace.ObjectIdentity

=end text

=back



=head2 ref_string

=over 4



=item Description

A chain of objects with references to one another as a string.

        A single string that is semantically identical to ref_chain above.
        Represents a path from one workspace object to another through an
        arbitrarily number of intermediate objects where each object has a
        dependency or provenance reference to the next object. Each entry is
        an obj_ref as defined earlier. Entries are separated by semicolons.
        Whitespace is ignored.
        
        Examples:
        3/5/6; kbaseuser:myworkspace/myobject; 5/myobject/2
        aworkspace/6


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 object_path

=over 4



=item Description

A path into an object. 
Identify a sub portion of an object by providing the path, delimited by
a slash (/), to that portion of the object. Thus the path may not have
slashes in the structure or mapping keys. Examples:
/foo/bar/3 - specifies the bar key of the foo mapping and the 3rd
        entry of the array if bar maps to an array or the value mapped to
        the string "3" if bar maps to a map.
/foo/bar/[*]/baz - specifies the baz field of all the objects in the
        list mapped by the bar key in the map foo.
/foo/asterisk/baz - specifies the baz field of all the objects in the
        values of the foo mapping. Swap 'asterisk' for * in the path.
In case you need to use '/' or '~' in path items use JSON Pointer 
        notation defined here: http://tools.ietf.org/html/rfc6901


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 SubObjectIdentity

=over 4



=item Description

DEPRECATED

        An object subset identifier.
        
        Select a subset of an object by:
        EITHER
                One, and only one, of the numerical id or name of the workspace.
                        ws_id wsid - the numerical ID of the workspace.
                        ws_name workspace - name of the workspace.
                AND 
                One, and only one, of the numerical id or name of the object.
                        obj_id objid- the numerical ID of the object.
                        obj_name name - name of the object.
                OPTIONALLY
                        obj_ver ver - the version of the object.
        OR an object reference string:
                obj_ref ref - an object reference string.
        AND a subset specification:
                list<object_path> included - the portions of the object to include
                        in the object subset.
        boolean strict_maps - if true, throw an exception if the subset
                specification traverses a non-existant map key (default false)
        boolean strict_arrays - if true, throw an exception if the subset
                specification exceeds the size of an array (default true)
                
        @deprecated Workspace.ObjectSpecification


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
wsid has a value which is a Workspace.ws_id
name has a value which is a Workspace.obj_name
objid has a value which is a Workspace.obj_id
ver has a value which is a Workspace.obj_ver
ref has a value which is a Workspace.obj_ref
included has a value which is a reference to a list where each element is a Workspace.object_path
strict_maps has a value which is a Workspace.boolean
strict_arrays has a value which is a Workspace.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
wsid has a value which is a Workspace.ws_id
name has a value which is a Workspace.obj_name
objid has a value which is a Workspace.obj_id
ver has a value which is a Workspace.obj_ver
ref has a value which is a Workspace.obj_ref
included has a value which is a reference to a list where each element is a Workspace.object_path
strict_maps has a value which is a Workspace.boolean
strict_arrays has a value which is a Workspace.boolean


=end text

=back



=head2 ObjectSpecification

=over 4



=item Description

An Object Specification (OS). Inherits from ObjectIdentity (OI).
Specifies which object, and which parts of that object, to retrieve
from the Workspace Service.

The fields wsid, workspace, objid, name, and ver are identical to
the OI fields.

The ref field's behavior is extended from OI. It maintains its
previous behavior, but now also can act as a reference string. See
reference following below for more information.

REFERENCE FOLLOWING:

Reference following guarantees that a user that has access to an
object can always see a) objects that are referenced inside the object
and b) objects that are referenced in the object's provenance. This
ensures that the user has visibility into the entire provenance of the
object and the object's object dependencies (e.g. references).

The user must have at least read access to the object specified in this
SO, but need not have access to any further objects in the reference
chain, and those objects may be deleted.

Optional reference following fields:
Note that only one of the following fields may be specified.

ref_chain obj_path - a path to the desired object from the object
        specified in this OS. In other words, the object specified in this
        OS is assumed to be accessible to the user, and the objects in
        the object path represent a chain of references to the desired
        object at the end of the object path. If the references are all
        valid, the desired object will be returned.
- OR -
list<obj_ref> obj_ref_path - shorthand for the obj_path.
- OR -
ref_chain to_obj_path - identical to obj_path, except that the path
        is TO the object specified in this OS, rather than from the object.
        In other words the object specified by wsid/objid/ref etc. is the
        end of the path, and to_obj_path is the rest of the path. The user
        must have access to the first object in the to_obj_path.
- OR -
list<obj_ref> to_obj_ref_path - shorthand for the to_obj_path.
- OR -
ref_string ref - A string representing a reference path from
        one object to another. Unlike the previous reference following
        options, the ref_string represents the ENTIRE path from the source
        object to the target object. As with the OI object, the ref field
        may contain a single reference.
- OR -
boolean find_refence_path - This is the last, slowest, and most expensive resort
        for getting a referenced object - do not use this method unless the
        path to the object is unavailable by any other means. Setting the
        find_refence_path parameter to true means that the workspace service will
        search through the object reference graph from the object specified
        in this OS to find an object that 1) the user can access, and 2)
        has an unbroken reference path to the target object. If the search
        succeeds, the object will be returned as normal. Note that the search
        will automatically fail after a certain (but much larger than necessary
        for the vast majority of cases) number of objects are traversed.
        

OBJECT SUBSETS:

When selecting a subset of an array in an object, the returned
array is compressed to the size of the subset, but the ordering of
the array is maintained. For example, if the array stored at the
'feature' key of a Genome object has 4000 entries, and the object paths
provided are:
        /feature/7
        /feature/3015
        /feature/700
The returned feature array will be of length three and the entries will
consist, in order, of the 7th, 700th, and 3015th entries of the
original array.

Optional object subset fields:
list<object_path> included - the portions of the object to include
                in the object subset.
boolean strict_maps - if true, throw an exception if the subset
        specification traverses a non-existent map key (default false)
boolean strict_arrays - if true, throw an exception if the subset
        specification exceeds the size of an array (default true)


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
wsid has a value which is a Workspace.ws_id
name has a value which is a Workspace.obj_name
objid has a value which is a Workspace.obj_id
ver has a value which is a Workspace.obj_ver
ref has a value which is a Workspace.ref_string
obj_path has a value which is a Workspace.ref_chain
obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
to_obj_path has a value which is a Workspace.ref_chain
to_obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
find_reference_path has a value which is a Workspace.boolean
included has a value which is a reference to a list where each element is a Workspace.object_path
strict_maps has a value which is a Workspace.boolean
strict_arrays has a value which is a Workspace.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
wsid has a value which is a Workspace.ws_id
name has a value which is a Workspace.obj_name
objid has a value which is a Workspace.obj_id
ver has a value which is a Workspace.obj_ver
ref has a value which is a Workspace.ref_string
obj_path has a value which is a Workspace.ref_chain
obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
to_obj_path has a value which is a Workspace.ref_chain
to_obj_ref_path has a value which is a reference to a list where each element is a Workspace.obj_ref
find_reference_path has a value which is a Workspace.boolean
included has a value which is a reference to a list where each element is a Workspace.object_path
strict_maps has a value which is a Workspace.boolean
strict_arrays has a value which is a Workspace.boolean


=end text

=back



=head2 object_metadata

=over 4



=item Description

Meta data associated with an object stored in a workspace. Provided for
backwards compatibility.
        
obj_name id - name of the object.
type_string type - type of the object.
timestamp moddate - date when the object was saved
obj_ver instance - the version of the object
string command - Deprecated. Always returns the empty string.
username lastmodifier - name of the user who last saved the object,
        including copying the object
username owner - Deprecated. Same as lastmodifier.
ws_name workspace - name of the workspace in which the object is
        stored
string ref - Deprecated. Always returns the empty string.
string chsum - the md5 checksum of the object.
usermeta metadata - arbitrary user-supplied metadata about
        the object.
obj_id objid - the numerical id of the object.

@deprecated object_info


=item Definition

=begin html

<pre>
a reference to a list containing 12 items:
0: (id) a Workspace.obj_name
1: (type) a Workspace.type_string
2: (moddate) a Workspace.timestamp
3: (instance) an int
4: (command) a string
5: (lastmodifier) a Workspace.username
6: (owner) a Workspace.username
7: (workspace) a Workspace.ws_name
8: (ref) a string
9: (chsum) a string
10: (metadata) a Workspace.usermeta
11: (objid) a Workspace.obj_id

</pre>

=end html

=begin text

a reference to a list containing 12 items:
0: (id) a Workspace.obj_name
1: (type) a Workspace.type_string
2: (moddate) a Workspace.timestamp
3: (instance) an int
4: (command) a string
5: (lastmodifier) a Workspace.username
6: (owner) a Workspace.username
7: (workspace) a Workspace.ws_name
8: (ref) a string
9: (chsum) a string
10: (metadata) a Workspace.usermeta
11: (objid) a Workspace.obj_id


=end text

=back



=head2 object_info

=over 4



=item Description

Information about an object, including user provided metadata.

        obj_id objid - the numerical id of the object.
        obj_name name - the name of the object.
        type_string type - the type of the object.
        timestamp save_date - the save date of the object.
        obj_ver ver - the version of the object.
        username saved_by - the user that saved or copied the object.
        ws_id wsid - the workspace containing the object.
        ws_name workspace - the workspace containing the object.
        string chsum - the md5 checksum of the object.
        int size - the size of the object in bytes.
        usermeta meta - arbitrary user-supplied metadata about
                the object.


=item Definition

=begin html

<pre>
a reference to a list containing 11 items:
0: (objid) a Workspace.obj_id
1: (name) a Workspace.obj_name
2: (type) a Workspace.type_string
3: (save_date) a Workspace.timestamp
4: (version) an int
5: (saved_by) a Workspace.username
6: (wsid) a Workspace.ws_id
7: (workspace) a Workspace.ws_name
8: (chsum) a string
9: (size) an int
10: (meta) a Workspace.usermeta

</pre>

=end html

=begin text

a reference to a list containing 11 items:
0: (objid) a Workspace.obj_id
1: (name) a Workspace.obj_name
2: (type) a Workspace.type_string
3: (save_date) a Workspace.timestamp
4: (version) an int
5: (saved_by) a Workspace.username
6: (wsid) a Workspace.ws_id
7: (workspace) a Workspace.ws_name
8: (chsum) a string
9: (size) an int
10: (meta) a Workspace.usermeta


=end text

=back



=head2 ExternalDataUnit

=over 4



=item Description

An external data unit. A piece of data from a source outside the
Workspace.

On input, only one of the resource_release_date or
resource_release_epoch may be supplied. Both are supplied on output.

string resource_name - the name of the resource, for example JGI.
string resource_url - the url of the resource, for example
        http://genome.jgi.doe.gov
string resource_version - version of the resource
timestamp resource_release_date - the release date of the resource
epoch resource_release_epoch - the release date of the resource
string data_url - the url of the data, for example
        http://genome.jgi.doe.gov/pages/dynamicOrganismDownload.jsf?
                organism=BlaspURHD0036
string data_id - the id of the data, for example
        7625.2.79179.AGTTCC.adnq.fastq.gz
string description - a free text description of the data.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
resource_name has a value which is a string
resource_url has a value which is a string
resource_version has a value which is a string
resource_release_date has a value which is a Workspace.timestamp
resource_release_epoch has a value which is a Workspace.epoch
data_url has a value which is a string
data_id has a value which is a string
description has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
resource_name has a value which is a string
resource_url has a value which is a string
resource_version has a value which is a string
resource_release_date has a value which is a Workspace.timestamp
resource_release_epoch has a value which is a Workspace.epoch
data_url has a value which is a string
data_id has a value which is a string
description has a value which is a string


=end text

=back



=head2 SubAction

=over 4



=item Description

Information about a subaction that is invoked by a provenance action.

        A provenance action (PA) may invoke subactions (SA), e.g. calling a
        separate piece of code, a service, or a script. In most cases these
        calls are the same from PA to PA and so do not need to be listed in
        the provenance since providing information about the PA alone provides
        reproducibility.
        
        In some cases, however, SAs may change over time, such that invoking
        the same PA with the same parameters may produce different results.
        For example, if a PA calls a remote server, that server may be updated
        between a PA invoked on day T and another PA invoked on day T+1.
        
        The SubAction structure allows for specifying information about SAs
        that may dynamically change from PA invocation to PA invocation.
        
        string name - the name of the SA.
        string ver - the version of SA.
        string code_url - a url pointing to the SA's codebase.
        string commit - a version control commit ID for the SA.
        string endpoint_url - a url pointing to the access point for the SA -
                a server url, for instance.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
name has a value which is a string
ver has a value which is a string
code_url has a value which is a string
commit has a value which is a string
endpoint_url has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
name has a value which is a string
ver has a value which is a string
code_url has a value which is a string
commit has a value which is a string
endpoint_url has a value which is a string


=end text

=back



=head2 ProvenanceAction

=over 4



=item Description

A provenance action.

        A provenance action (PA) is an action taken while transforming one data
        object to another. There may be several PAs taken in series. A PA is
        typically running a script, running an api command, etc. All of the
        following fields are optional, but more information provided equates to
        better data provenance.
        
        resolved_ws_objects should never be set by the user; it is set by the
        workspace service when returning data.
        
        On input, only one of the time or epoch may be supplied. Both are
        supplied on output.
        
        The maximum size of the entire provenance object, including all actions,
        is 1MB.
        
        timestamp time - the time the action was started
        epoch epoch - the time the action was started.
        string caller - the name or id of the invoker of this provenance
                action. In most cases, this will be the same for all PAs.
        string service - the name of the service that performed this action.
        string service_ver - the version of the service that performed this action.
        string method - the method of the service that performed this action.
        list<UnspecifiedObject> method_params - the parameters of the method
                that performed this action. If an object in the parameters is a
                workspace object, also put the object reference in the
                input_ws_object list.
        string script - the name of the script that performed this action.
        string script_ver - the version of the script that performed this action.
        string script_command_line - the command line provided to the script
                that performed this action. If workspace objects were provided in
                the command line, also put the object reference in the
                input_ws_object list.
        list<ref_string> input_ws_objects - the workspace objects that
                were used as input to this action; typically these will also be
                present as parts of the method_params or the script_command_line
                arguments. A reference path into the object graph may be supplied.
        list<obj_ref> resolved_ws_objects - the workspace objects ids from 
                input_ws_objects resolved to permanent workspace object references
                by the workspace service.
        list<string> intermediate_incoming - if the previous action produced 
                output that 1) was not stored in a referrable way, and 2) is
                used as input for this action, provide it with an arbitrary and
                unique ID here, in the order of the input arguments to this action.
                These IDs can be used in the method_params argument.
        list<string> intermediate_outgoing - if this action produced output
                that 1) was not stored in a referrable way, and 2) is
                used as input for the next action, provide it with an arbitrary and
                unique ID here, in the order of the output values from this action.
                These IDs can be used in the intermediate_incoming argument in the
                next action.
        list<ExternalDataUnit> external_data - data external to the workspace
                that was either imported to the workspace or used to create a
                workspace object.
        list<SubAction> subactions - the subactions taken as a part of this
                action.
        mapping<string, string> custom - user definable custom provenance
                fields and their values.
        string description - a free text description of this action.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
time has a value which is a Workspace.timestamp
epoch has a value which is a Workspace.epoch
caller has a value which is a string
service has a value which is a string
service_ver has a value which is a string
method has a value which is a string
method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
script has a value which is a string
script_ver has a value which is a string
script_command_line has a value which is a string
input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
intermediate_incoming has a value which is a reference to a list where each element is a string
intermediate_outgoing has a value which is a reference to a list where each element is a string
external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
subactions has a value which is a reference to a list where each element is a Workspace.SubAction
custom has a value which is a reference to a hash where the key is a string and the value is a string
description has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
time has a value which is a Workspace.timestamp
epoch has a value which is a Workspace.epoch
caller has a value which is a string
service has a value which is a string
service_ver has a value which is a string
method has a value which is a string
method_params has a value which is a reference to a list where each element is an UnspecifiedObject, which can hold any non-null object
script has a value which is a string
script_ver has a value which is a string
script_command_line has a value which is a string
input_ws_objects has a value which is a reference to a list where each element is a Workspace.ref_string
resolved_ws_objects has a value which is a reference to a list where each element is a Workspace.obj_ref
intermediate_incoming has a value which is a reference to a list where each element is a string
intermediate_outgoing has a value which is a reference to a list where each element is a string
external_data has a value which is a reference to a list where each element is a Workspace.ExternalDataUnit
subactions has a value which is a reference to a list where each element is a Workspace.SubAction
custom has a value which is a reference to a hash where the key is a string and the value is a string
description has a value which is a string


=end text

=back



=head2 CreateWorkspaceParams

=over 4



=item Description

Input parameters for the "create_workspace" function.

        Required arguments:
        ws_name workspace - name of the workspace to be created.
        
        Optional arguments:
        permission globalread - 'r' to set the new workspace globally readable,
                default 'n'.
        string description - A free-text description of the new workspace, 1000
                characters max. Longer strings will be mercilessly and brutally
                truncated.
        usermeta meta - arbitrary user-supplied metadata for the workspace.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
globalread has a value which is a Workspace.permission
description has a value which is a string
meta has a value which is a Workspace.usermeta

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
globalread has a value which is a Workspace.permission
description has a value which is a string
meta has a value which is a Workspace.usermeta


=end text

=back



=head2 AlterWorkspaceMetadataParams

=over 4



=item Description

Input parameters for the "alter_workspace_metadata" function.

Required arguments:
WorkspaceIdentity wsi - the workspace to be altered

One or both of the following arguments are required:
usermeta new - metadata to assign to the workspace. Duplicate keys will
        be overwritten.
list<string> remove - these keys will be removed from the workspace
        metadata key/value pairs.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
wsi has a value which is a Workspace.WorkspaceIdentity
new has a value which is a Workspace.usermeta
remove has a value which is a reference to a list where each element is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
wsi has a value which is a Workspace.WorkspaceIdentity
new has a value which is a Workspace.usermeta
remove has a value which is a reference to a list where each element is a string


=end text

=back



=head2 CloneWorkspaceParams

=over 4



=item Description

Input parameters for the "clone_workspace" function.

        Note that deleted objects are not cloned, although hidden objects are
        and remain hidden in the new workspace.

        Required arguments:
        WorkspaceIdentity wsi - the workspace to be cloned.
        ws_name workspace - name of the workspace to be cloned into. This must
                be a non-existant workspace name.
        
        Optional arguments:
        permission globalread - 'r' to set the new workspace globally readable,
                default 'n'.
        string description - A free-text description of the new workspace, 1000
                characters max. Longer strings will be mercilessly and brutally
                truncated.
        usermeta meta - arbitrary user-supplied metadata for the workspace.
        list<ObjectIdentity> exclude - exclude the specified objects from the
                cloned workspace. Either an object ID or a object name must be
                specified in each ObjectIdentity - any supplied reference strings,
                workspace names or IDs, and versions are ignored.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
wsi has a value which is a Workspace.WorkspaceIdentity
workspace has a value which is a Workspace.ws_name
globalread has a value which is a Workspace.permission
description has a value which is a string
meta has a value which is a Workspace.usermeta
exclude has a value which is a reference to a list where each element is a Workspace.ObjectIdentity

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
wsi has a value which is a Workspace.WorkspaceIdentity
workspace has a value which is a Workspace.ws_name
globalread has a value which is a Workspace.permission
description has a value which is a string
meta has a value which is a Workspace.usermeta
exclude has a value which is a reference to a list where each element is a Workspace.ObjectIdentity


=end text

=back



=head2 get_workspacemeta_params

=over 4



=item Description

DEPRECATED

        Input parameters for the "get_workspacemeta" function. Provided for
        backwards compatibility.

        One, and only one of:
        ws_name workspace - name of the workspace.
        ws_id id - the numerical ID of the workspace.
                
        Optional arguments:
        string auth - the authentication token of the KBase account accessing
                the workspace. Overrides the client provided authorization
                credentials if they exist.
        
        @deprecated Workspace.WorkspaceIdentity


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
id has a value which is a Workspace.ws_id
auth has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
id has a value which is a Workspace.ws_id
auth has a value which is a string


=end text

=back



=head2 SetPermissionsParams

=over 4



=item Description

Input parameters for the "set_permissions" function.

        One, and only one, of the following is required:
        ws_id id - the numerical ID of the workspace.
        ws_name workspace - the name of the workspace.
        
        Required arguments:
        permission new_permission - the permission to assign to the users.
        list<username> users - the users whose permissions will be altered.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
id has a value which is a Workspace.ws_id
new_permission has a value which is a Workspace.permission
users has a value which is a reference to a list where each element is a Workspace.username

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
id has a value which is a Workspace.ws_id
new_permission has a value which is a Workspace.permission
users has a value which is a reference to a list where each element is a Workspace.username


=end text

=back



=head2 SetGlobalPermissionsParams

=over 4



=item Description

Input parameters for the "set_global_permission" function.

        One, and only one, of the following is required:
        ws_id id - the numerical ID of the workspace.
        ws_name workspace - the name of the workspace.
        
        Required arguments:
        permission new_permission - the permission to assign to all users,
                either 'n' or 'r'. 'r' means that all users will be able to read
                the workspace; otherwise users must have specific permission to
                access the workspace.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
id has a value which is a Workspace.ws_id
new_permission has a value which is a Workspace.permission

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
id has a value which is a Workspace.ws_id
new_permission has a value which is a Workspace.permission


=end text

=back



=head2 SetWorkspaceDescriptionParams

=over 4



=item Description

Input parameters for the "set_workspace_description" function.

        One, and only one, of the following is required:
        ws_id id - the numerical ID of the workspace.
        ws_name workspace - the name of the workspace.
        
        Optional arguments:
        string description - A free-text description of the workspace, 1000
                characters max. Longer strings will be mercilessly and brutally
                truncated. If omitted, the description is set to null.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
id has a value which is a Workspace.ws_id
description has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
id has a value which is a Workspace.ws_id
description has a value which is a string


=end text

=back



=head2 GetPermissionsMassParams

=over 4



=item Description

Input parameters for the "get_permissions_mass" function.
workspaces - the workspaces for which to return the permissions,
        maximum 1000.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspaces has a value which is a reference to a list where each element is a Workspace.WorkspaceIdentity

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspaces has a value which is a reference to a list where each element is a Workspace.WorkspaceIdentity


=end text

=back



=head2 WorkspacePermissions

=over 4



=item Description

A set of workspace permissions.
perms - the list of permissions for each requested workspace


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
perms has a value which is a reference to a list where each element is a reference to a hash where the key is a Workspace.username and the value is a Workspace.permission

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
perms has a value which is a reference to a list where each element is a reference to a hash where the key is a Workspace.username and the value is a Workspace.permission


=end text

=back



=head2 save_object_params

=over 4



=item Description

Input parameters for the "save_object" function. Provided for backwards
compatibility.
        
Required arguments:
type_string type - type of the object to be saved
ws_name workspace - name of the workspace where the object is to be
        saved
obj_name id - name behind which the object will be saved in the
        workspace
UnspecifiedObject data - data to be saved in the workspace

Optional arguments:
usermeta metadata - arbitrary user-supplied metadata for the object,
        not to exceed 16kb; if the object type specifies automatic
        metadata extraction with the 'meta ws' annotation, and your
        metadata name conflicts, then your metadata will be silently
        overwritten.
string auth - the authentication token of the KBase account accessing
        the workspace. Overrides the client provided authorization
        credentials if they exist.

@deprecated


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a Workspace.obj_name
type has a value which is a Workspace.type_string
data has a value which is an UnspecifiedObject, which can hold any non-null object
workspace has a value which is a Workspace.ws_name
metadata has a value which is a reference to a hash where the key is a string and the value is a string
auth has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a Workspace.obj_name
type has a value which is a Workspace.type_string
data has a value which is an UnspecifiedObject, which can hold any non-null object
workspace has a value which is a Workspace.ws_name
metadata has a value which is a reference to a hash where the key is a string and the value is a string
auth has a value which is a string


=end text

=back



=head2 ObjectSaveData

=over 4



=item Description

An object and associated data required for saving.

        Required arguments:
        type_string type - the type of the object. Omit the version information
                to use the latest version.
        UnspecifiedObject data - the object data.
        
        Optional arguments:
        One of an object name or id. If no name or id is provided the name
                will be set to 'auto' with the object id appended as a string,
                possibly with -\d+ appended if that object id already exists as a
                name.
        obj_name name - the name of the object.
        obj_id objid - the id of the object to save over.
        usermeta meta - arbitrary user-supplied metadata for the object,
                not to exceed 16kb; if the object type specifies automatic
                metadata extraction with the 'meta ws' annotation, and your
                metadata name conflicts, then your metadata will be silently
                overwritten.
        list<ProvenanceAction> provenance - provenance data for the object.
        boolean hidden - true if this object should not be listed when listing
                workspace objects.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
type has a value which is a Workspace.type_string
data has a value which is an UnspecifiedObject, which can hold any non-null object
name has a value which is a Workspace.obj_name
objid has a value which is a Workspace.obj_id
meta has a value which is a Workspace.usermeta
provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
hidden has a value which is a Workspace.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
type has a value which is a Workspace.type_string
data has a value which is an UnspecifiedObject, which can hold any non-null object
name has a value which is a Workspace.obj_name
objid has a value which is a Workspace.obj_id
meta has a value which is a Workspace.usermeta
provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
hidden has a value which is a Workspace.boolean


=end text

=back



=head2 SaveObjectsParams

=over 4



=item Description

Input parameters for the "save_objects" function.

        One, and only one, of the following is required:
        ws_id id - the numerical ID of the workspace.
        ws_name workspace - the name of the workspace.
        
        Required arguments:
        list<ObjectSaveData> objects - the objects to save.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
id has a value which is a Workspace.ws_id
objects has a value which is a reference to a list where each element is a Workspace.ObjectSaveData

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
id has a value which is a Workspace.ws_id
objects has a value which is a reference to a list where each element is a Workspace.ObjectSaveData


=end text

=back



=head2 get_object_params

=over 4



=item Description

Input parameters for the "get_object" function. Provided for backwards
compatibility.
        
Required arguments:
ws_name workspace - Name of the workspace containing the object to be
        retrieved
obj_name id - Name of the object to be retrieved

Optional arguments:
int instance - Version of the object to be retrieved, enabling
        retrieval of any previous version of an object
string auth - the authentication token of the KBase account accessing
        the object. Overrides the client provided authorization
        credentials if they exist.

@deprecated Workspace.ObjectIdentity


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a Workspace.obj_name
workspace has a value which is a Workspace.ws_name
instance has a value which is an int
auth has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a Workspace.obj_name
workspace has a value which is a Workspace.ws_name
instance has a value which is an int
auth has a value which is a string


=end text

=back



=head2 get_object_output

=over 4



=item Description

Output generated by the "get_object" function. Provided for backwards
compatibility.
        
UnspecifiedObject data - The object's data.
object_metadata metadata - Metadata for object retrieved/
        
@deprecated Workspaces.ObjectData


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
data has a value which is an UnspecifiedObject, which can hold any non-null object
metadata has a value which is a Workspace.object_metadata

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
data has a value which is an UnspecifiedObject, which can hold any non-null object
metadata has a value which is a Workspace.object_metadata


=end text

=back



=head2 ObjectProvenanceInfo

=over 4



=item Description

DEPRECATED

        The provenance and supplemental info for an object.

        object_info info - information about the object.
        list<ProvenanceAction> provenance - the object's provenance.
        username creator - the user that first saved the object to the
                workspace.
        ws_id orig_wsid - the id of the workspace in which this object was
                        originally saved. Missing for objects saved prior to version
                        0.4.1.
        timestamp created - the date the object was first saved to the
                workspace.
        epoch epoch - the date the object was first saved to the
                workspace.
        list<obj_ref> - the references contained within the object.
        obj_ref copied - the reference of the source object if this object is
                a copy and the copy source exists and is accessible.
                null otherwise.
        boolean copy_source_inaccessible - true if the object was copied from
                another object, but that object is no longer accessible to the
                user. False otherwise.
        mapping<id_type, list<extracted_id>> extracted_ids - any ids extracted
                from the object.
        string handle_error - if an error occurs while setting ACLs on
                embedded handle IDs, it will be reported here.
        string handle_stacktrace - the stacktrace for handle_error.
        
        @deprecated


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
info has a value which is a Workspace.object_info
provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
creator has a value which is a Workspace.username
orig_wsid has a value which is a Workspace.ws_id
created has a value which is a Workspace.timestamp
epoch has a value which is a Workspace.epoch
refs has a value which is a reference to a list where each element is a Workspace.obj_ref
copied has a value which is a Workspace.obj_ref
copy_source_inaccessible has a value which is a Workspace.boolean
extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
handle_error has a value which is a string
handle_stacktrace has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
info has a value which is a Workspace.object_info
provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
creator has a value which is a Workspace.username
orig_wsid has a value which is a Workspace.ws_id
created has a value which is a Workspace.timestamp
epoch has a value which is a Workspace.epoch
refs has a value which is a reference to a list where each element is a Workspace.obj_ref
copied has a value which is a Workspace.obj_ref
copy_source_inaccessible has a value which is a Workspace.boolean
extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
handle_error has a value which is a string
handle_stacktrace has a value which is a string


=end text

=back



=head2 ObjectData

=over 4



=item Description

The data and supplemental info for an object.

        UnspecifiedObject data - the object's data or subset data.
        object_info info - information about the object.
        list<obj_ref> path - the path to the object through the object reference graph. All the
                references in the path are absolute.
        list<ProvenanceAction> provenance - the object's provenance.
        username creator - the user that first saved the object to the workspace.
        ws_id orig_wsid - the id of the workspace in which this object was
                        originally saved. Missing for objects saved prior to version
                        0.4.1.
        timestamp created - the date the object was first saved to the
                workspace.
        epoch epoch - the date the object was first saved to the
                workspace.
        list<obj_ref> refs - the references contained within the object.
        obj_ref copied - the reference of the source object if this object is
                a copy and the copy source exists and is accessible.
                null otherwise.
        boolean copy_source_inaccessible - true if the object was copied from
                another object, but that object is no longer accessible to the
                user. False otherwise.
        mapping<id_type, list<extracted_id>> extracted_ids - any ids extracted
                from the object.
        string handle_error - if an error occurs while setting ACLs on
                embedded handle IDs, it will be reported here.
        string handle_stacktrace - the stacktrace for handle_error.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
data has a value which is an UnspecifiedObject, which can hold any non-null object
info has a value which is a Workspace.object_info
path has a value which is a reference to a list where each element is a Workspace.obj_ref
provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
creator has a value which is a Workspace.username
orig_wsid has a value which is a Workspace.ws_id
created has a value which is a Workspace.timestamp
epoch has a value which is a Workspace.epoch
refs has a value which is a reference to a list where each element is a Workspace.obj_ref
copied has a value which is a Workspace.obj_ref
copy_source_inaccessible has a value which is a Workspace.boolean
extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
handle_error has a value which is a string
handle_stacktrace has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
data has a value which is an UnspecifiedObject, which can hold any non-null object
info has a value which is a Workspace.object_info
path has a value which is a reference to a list where each element is a Workspace.obj_ref
provenance has a value which is a reference to a list where each element is a Workspace.ProvenanceAction
creator has a value which is a Workspace.username
orig_wsid has a value which is a Workspace.ws_id
created has a value which is a Workspace.timestamp
epoch has a value which is a Workspace.epoch
refs has a value which is a reference to a list where each element is a Workspace.obj_ref
copied has a value which is a Workspace.obj_ref
copy_source_inaccessible has a value which is a Workspace.boolean
extracted_ids has a value which is a reference to a hash where the key is a Workspace.id_type and the value is a reference to a list where each element is a Workspace.extracted_id
handle_error has a value which is a string
handle_stacktrace has a value which is a string


=end text

=back



=head2 GetObjects2Params

=over 4



=item Description

Input parameters for the get_objects2 function.

        Required parameters:
        list<ObjectSpecification> objects - the list of object specifications
                for the objects to return (via reference chain and as a subset if
                specified).
                
        Optional parameters:
        boolean ignoreErrors - Don't throw an exception if an object cannot
                be accessed; return null for that object's information instead.
                Default false.
        boolean no_data - return the provenance, references, and
                object_info for this object without the object data. Default false.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
objects has a value which is a reference to a list where each element is a Workspace.ObjectSpecification
ignoreErrors has a value which is a Workspace.boolean
no_data has a value which is a Workspace.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
objects has a value which is a reference to a list where each element is a Workspace.ObjectSpecification
ignoreErrors has a value which is a Workspace.boolean
no_data has a value which is a Workspace.boolean


=end text

=back



=head2 GetObjects2Results

=over 4



=item Description

Results from the get_objects2 function.

        list<ObjectData> data - the returned objects.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
data has a value which is a reference to a list where each element is a Workspace.ObjectData

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
data has a value which is a reference to a list where each element is a Workspace.ObjectData


=end text

=back



=head2 list_workspaces_params

=over 4



=item Description

Input parameters for the "list_workspaces" function. Provided for
backwards compatibility.

Optional parameters:
string auth - the authentication token of the KBase account accessing
        the list of workspaces. Overrides the client provided authorization
        credentials if they exist.
boolean excludeGlobal - if excludeGlobal is true exclude world
        readable workspaces. Defaults to false.

@deprecated Workspace.ListWorkspaceInfoParams


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
auth has a value which is a string
excludeGlobal has a value which is a Workspace.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
auth has a value which is a string
excludeGlobal has a value which is a Workspace.boolean


=end text

=back



=head2 ListWorkspaceInfoParams

=over 4



=item Description

Input parameters for the "list_workspace_info" function.

Only one of each timestamp/epoch pair may be supplied.

Optional parameters:
permission perm - filter workspaces by minimum permission level. 'None'
        and 'readable' are ignored.
list<username> owners - filter workspaces by owner.
usermeta meta - filter workspaces by the user supplied metadata. NOTE:
        only one key/value pair is supported at this time. A full map
        is provided as input for the possibility for expansion in the
        future.
timestamp after - only return workspaces that were modified after this
        date.
timestamp before - only return workspaces that were modified before
        this date.
epoch after_epoch - only return workspaces that were modified after
        this date.
epoch before_epoch - only return workspaces that were modified before
        this date.
boolean excludeGlobal - if excludeGlobal is true exclude world
        readable workspaces. Defaults to false.
boolean showDeleted - show deleted workspaces that are owned by the
        user.
boolean showOnlyDeleted - only show deleted workspaces that are owned
        by the user.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
perm has a value which is a Workspace.permission
owners has a value which is a reference to a list where each element is a Workspace.username
meta has a value which is a Workspace.usermeta
after has a value which is a Workspace.timestamp
before has a value which is a Workspace.timestamp
after_epoch has a value which is a Workspace.epoch
before_epoch has a value which is a Workspace.epoch
excludeGlobal has a value which is a Workspace.boolean
showDeleted has a value which is a Workspace.boolean
showOnlyDeleted has a value which is a Workspace.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
perm has a value which is a Workspace.permission
owners has a value which is a reference to a list where each element is a Workspace.username
meta has a value which is a Workspace.usermeta
after has a value which is a Workspace.timestamp
before has a value which is a Workspace.timestamp
after_epoch has a value which is a Workspace.epoch
before_epoch has a value which is a Workspace.epoch
excludeGlobal has a value which is a Workspace.boolean
showDeleted has a value which is a Workspace.boolean
showOnlyDeleted has a value which is a Workspace.boolean


=end text

=back



=head2 list_workspace_objects_params

=over 4



=item Description

Input parameters for the "list_workspace_objects" function. Provided
for backwards compatibility.

Required arguments:
ws_name workspace - Name of the workspace for which objects should be
        listed

Optional arguments:
type_string type - type of the objects to be listed. Here, omitting
        version information will find any objects that match the provided
        type - e.g. Foo.Bar-0 will match Foo.Bar-0.X where X is any
        existing version.
boolean showDeletedObject - show objects that have been deleted
string auth - the authentication token of the KBase account requesting
        access. Overrides the client provided authorization credentials if
        they exist.
        
@deprecated Workspace.ListObjectsParams


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
type has a value which is a Workspace.type_string
showDeletedObject has a value which is a Workspace.boolean
auth has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspace has a value which is a Workspace.ws_name
type has a value which is a Workspace.type_string
showDeletedObject has a value which is a Workspace.boolean
auth has a value which is a string


=end text

=back



=head2 ListObjectsParams

=over 4



=item Description

Parameters for the 'list_objects' function.

                At least one of the following filters must be provided. It is strongly
                recommended that the list is restricted to the workspaces of interest,
                or the results may be very large:
                list<ws_id> ids - the numerical IDs of the workspaces of interest.
                list<ws_name> workspaces - the names of the workspaces of interest.
                type_string type - type of the objects to be listed.  Here, omitting
                        version information will find any objects that match the provided
                        type - e.g. Foo.Bar-0 will match Foo.Bar-0.X where X is any
                        existing version.
                
                Only one of each timestamp/epoch pair may be supplied.
                
                Optional arguments:
                permission perm - filter objects by minimum permission level. 'None'
                        and 'readable' are ignored.
                list<username> savedby - filter objects by the user that saved or
                        copied the object.
                usermeta meta - filter objects by the user supplied metadata. NOTE:
                        only one key/value pair is supported at this time. A full map
                        is provided as input for the possibility for expansion in the
                        future.
                timestamp after - only return objects that were created after this
                        date.
                timestamp before - only return objects that were created before this
                        date.
                epoch after_epoch - only return objects that were created after this
                        date.
                epoch before_epoch - only return objects that were created before this
                        date.
                obj_id minObjectID - only return objects with an object id greater or
                        equal to this value.
                obj_id maxObjectID - only return objects with an object id less than or
                        equal to this value.
                boolean showDeleted - show deleted objects in workspaces to which the
                        user has write access.
                boolean showOnlyDeleted - only show deleted objects in workspaces to
                        which the user has write access.
                boolean showHidden - show hidden objects.
                boolean showAllVersions - show all versions of each object that match
                        the filters rather than only the most recent version.
                boolean includeMetadata - include the user provided metadata in the
                        returned object_info. If false (0 or null), the default, the
                        metadata will be null.
                boolean excludeGlobal - exclude objects in global workspaces. This
                        parameter only has an effect when filtering by types alone.
                int limit - limit the output to X objects. Default and maximum value
                        is 10000. Limit values < 1 are treated as 10000, the default.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspaces has a value which is a reference to a list where each element is a Workspace.ws_name
ids has a value which is a reference to a list where each element is a Workspace.ws_id
type has a value which is a Workspace.type_string
perm has a value which is a Workspace.permission
savedby has a value which is a reference to a list where each element is a Workspace.username
meta has a value which is a Workspace.usermeta
after has a value which is a Workspace.timestamp
before has a value which is a Workspace.timestamp
after_epoch has a value which is a Workspace.epoch
before_epoch has a value which is a Workspace.epoch
minObjectID has a value which is a Workspace.obj_id
maxObjectID has a value which is a Workspace.obj_id
showDeleted has a value which is a Workspace.boolean
showOnlyDeleted has a value which is a Workspace.boolean
showHidden has a value which is a Workspace.boolean
showAllVersions has a value which is a Workspace.boolean
includeMetadata has a value which is a Workspace.boolean
excludeGlobal has a value which is a Workspace.boolean
limit has a value which is an int

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspaces has a value which is a reference to a list where each element is a Workspace.ws_name
ids has a value which is a reference to a list where each element is a Workspace.ws_id
type has a value which is a Workspace.type_string
perm has a value which is a Workspace.permission
savedby has a value which is a reference to a list where each element is a Workspace.username
meta has a value which is a Workspace.usermeta
after has a value which is a Workspace.timestamp
before has a value which is a Workspace.timestamp
after_epoch has a value which is a Workspace.epoch
before_epoch has a value which is a Workspace.epoch
minObjectID has a value which is a Workspace.obj_id
maxObjectID has a value which is a Workspace.obj_id
showDeleted has a value which is a Workspace.boolean
showOnlyDeleted has a value which is a Workspace.boolean
showHidden has a value which is a Workspace.boolean
showAllVersions has a value which is a Workspace.boolean
includeMetadata has a value which is a Workspace.boolean
excludeGlobal has a value which is a Workspace.boolean
limit has a value which is an int


=end text

=back



=head2 get_objectmeta_params

=over 4



=item Description

Input parameters for the "get_objectmeta" function.

        Required arguments:
        ws_name workspace - name of the workspace containing the object for
                 which metadata is to be retrieved
        obj_name id - name of the object for which metadata is to be retrieved
        
        Optional arguments:
        int instance - Version of the object for which metadata is to be
                 retrieved, enabling retrieval of any previous version of an object
        string auth - the authentication token of the KBase account requesting
                access. Overrides the client provided authorization credentials if
                they exist.
                
        @deprecated Workspace.ObjectIdentity


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
id has a value which is a Workspace.obj_name
workspace has a value which is a Workspace.ws_name
instance has a value which is an int
auth has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
id has a value which is a Workspace.obj_name
workspace has a value which is a Workspace.ws_name
instance has a value which is an int
auth has a value which is a string


=end text

=back



=head2 GetObjectInfoNewParams

=over 4



=item Description

Input parameters for the "get_object_info_new" function.

        Required arguments:
        list<ObjectSpecification> objects - the objects for which the
                information should be fetched. Subsetting related parameters are
                ignored.
        
        Optional arguments:
        boolean includeMetadata - include the object metadata in the returned
                information. Default false.
        boolean ignoreErrors - Don't throw an exception if an object cannot
                be accessed; return null for that object's information instead.
                Default false.
                
        @deprecated Workspace.GetObjectInfo3Params


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
objects has a value which is a reference to a list where each element is a Workspace.ObjectSpecification
includeMetadata has a value which is a Workspace.boolean
ignoreErrors has a value which is a Workspace.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
objects has a value which is a reference to a list where each element is a Workspace.ObjectSpecification
includeMetadata has a value which is a Workspace.boolean
ignoreErrors has a value which is a Workspace.boolean


=end text

=back



=head2 GetObjectInfo3Params

=over 4



=item Description

Input parameters for the "get_object_info3" function.

        Required arguments:
        list<ObjectSpecification> objects - the objects for which the
                information should be fetched. Subsetting related parameters are
                ignored.
        
        Optional arguments:
        boolean includeMetadata - include the object metadata in the returned
                information. Default false.
        boolean ignoreErrors - Don't throw an exception if an object cannot
                be accessed; return null for that object's information and path instead.
                Default false.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
objects has a value which is a reference to a list where each element is a Workspace.ObjectSpecification
includeMetadata has a value which is a Workspace.boolean
ignoreErrors has a value which is a Workspace.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
objects has a value which is a reference to a list where each element is a Workspace.ObjectSpecification
includeMetadata has a value which is a Workspace.boolean
ignoreErrors has a value which is a Workspace.boolean


=end text

=back



=head2 GetObjectInfo3Results

=over 4



=item Description

Output from the get_object_info3 function.

        list<object_info> infos - the object_info data for each object.
        list<list<obj_ref> paths - the path to the object through the object reference graph for
                each object. All the references in the path are absolute.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
infos has a value which is a reference to a list where each element is a Workspace.object_info
paths has a value which is a reference to a list where each element is a reference to a list where each element is a Workspace.obj_ref

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
infos has a value which is a reference to a list where each element is a Workspace.object_info
paths has a value which is a reference to a list where each element is a reference to a list where each element is a Workspace.obj_ref


=end text

=back



=head2 RenameWorkspaceParams

=over 4



=item Description

Input parameters for the 'rename_workspace' function.

Required arguments:
WorkspaceIdentity wsi - the workspace to rename.
ws_name new_name - the new name for the workspace.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
wsi has a value which is a Workspace.WorkspaceIdentity
new_name has a value which is a Workspace.ws_name

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
wsi has a value which is a Workspace.WorkspaceIdentity
new_name has a value which is a Workspace.ws_name


=end text

=back



=head2 RenameObjectParams

=over 4



=item Description

Input parameters for the 'rename_object' function.

Required arguments:
ObjectIdentity obj - the object to rename.
obj_name new_name - the new name for the object.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
obj has a value which is a Workspace.ObjectIdentity
new_name has a value which is a Workspace.obj_name

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
obj has a value which is a Workspace.ObjectIdentity
new_name has a value which is a Workspace.obj_name


=end text

=back



=head2 CopyObjectParams

=over 4



=item Description

Input parameters for the 'copy_object' function. 

        If the 'from' ObjectIdentity includes no version and the object is
        copied to a new name, the entire version history of the object is
        copied. In all other cases only the version specified, or the latest
        version if no version is specified, is copied.
        
        The version from the 'to' ObjectIdentity is always ignored.
        
        Required arguments:
        ObjectIdentity from - the object to copy.
        ObjectIdentity to - where to copy the object.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
from has a value which is a Workspace.ObjectIdentity
to has a value which is a Workspace.ObjectIdentity

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
from has a value which is a Workspace.ObjectIdentity
to has a value which is a Workspace.ObjectIdentity


=end text

=back



=head2 GetNamesByPrefixParams

=over 4



=item Description

Input parameters for the get_names_by_prefix function.

        Required arguments:
        list<WorkspaceIdentity> workspaces - the workspaces to search.
        string prefix - the prefix of the object names to return.
        
        Optional arguments:
        boolean includeHidden - include names of hidden objects in the results.
                Default false.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
workspaces has a value which is a reference to a list where each element is a Workspace.WorkspaceIdentity
prefix has a value which is a string
includeHidden has a value which is a Workspace.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
workspaces has a value which is a reference to a list where each element is a Workspace.WorkspaceIdentity
prefix has a value which is a string
includeHidden has a value which is a Workspace.boolean


=end text

=back



=head2 GetNamesByPrefixResults

=over 4



=item Description

Results object for the get_names_by_prefix function.

        list<list<obj_name>> names - the names matching the provided prefix,
                listed in order of the input workspaces.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
names has a value which is a reference to a list where each element is a reference to a list where each element is a Workspace.obj_name

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
names has a value which is a reference to a list where each element is a reference to a list where each element is a Workspace.obj_name


=end text

=back



=head2 typespec

=over 4



=item Description

A type specification (typespec) file in the KBase Interface Description
Language (KIDL).


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 modulename

=over 4



=item Description

A module name defined in a KIDL typespec.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 typename

=over 4



=item Description

A type definition name in a KIDL typespec.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 typever

=over 4



=item Description

A version of a type. 
Specifies the version of the type  in a single string in the format
[major].[minor]:

major - an integer. The major version of the type. A change in the
        major version implies the type has changed in a non-backwards
        compatible way.
minor - an integer. The minor version of the type. A change in the
        minor version implies that the type has changed in a way that is
        backwards compatible with previous type definitions.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 func_string

=over 4



=item Description

A function string for referencing a funcdef.
Specifies the function and its version in a single string in the format
[modulename].[funcname]-[major].[minor]:

modulename - a string. The name of the module containing the function.
funcname - a string. The name of the function as assigned by the funcdef
        statement.
major - an integer. The major version of the function. A change in the
        major version implies the function has changed in a non-backwards
        compatible way.
minor - an integer. The minor version of the function. A change in the
        minor version implies that the function has changed in a way that is
        backwards compatible with previous function definitions.

In many cases, the major and minor versions are optional, and if not
provided the most recent version will be used.

Example: MyModule.MyFunc-3.1


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 spec_version

=over 4



=item Description

The version of a typespec file.


=item Definition

=begin html

<pre>
an int
</pre>

=end html

=begin text

an int

=end text

=back



=head2 jsonschema

=over 4



=item Description

The JSON Schema (v4) representation of a type definition.


=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 RegisterTypespecParams

=over 4



=item Description

Parameters for the register_typespec function.

        Required arguments:
        One of:
        typespec spec - the new typespec to register.
        modulename mod - the module to recompile with updated options (see below).
        
        Optional arguments:
        boolean dryrun - Return, but do not save, the results of compiling the 
                spec. Default true. Set to false for making permanent changes.
        list<typename> new_types - types in the spec to make available in the
                workspace service. When compiling a spec for the first time, if
                this argument is empty no types will be made available. Previously
                available types remain so upon recompilation of a spec or
                compilation of a new spec.
        list<typename> remove_types - no longer make these types available in
                the workspace service for the new version of the spec. This does
                not remove versions of types previously compiled.
        mapping<modulename, spec_version> dependencies - By default, the
                latest released versions of spec dependencies will be included when
                compiling a spec. Specific versions can be specified here.
        spec_version prev_ver - the id of the previous version of the typespec.
                An error will be thrown if this is set and prev_ver is not the
                most recent version of the typespec. This prevents overwriting of
                changes made since retrieving a spec and compiling an edited spec.
                This argument is ignored if a modulename is passed.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
spec has a value which is a Workspace.typespec
mod has a value which is a Workspace.modulename
new_types has a value which is a reference to a list where each element is a Workspace.typename
remove_types has a value which is a reference to a list where each element is a Workspace.typename
dependencies has a value which is a reference to a hash where the key is a Workspace.modulename and the value is a Workspace.spec_version
dryrun has a value which is a Workspace.boolean
prev_ver has a value which is a Workspace.spec_version

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
spec has a value which is a Workspace.typespec
mod has a value which is a Workspace.modulename
new_types has a value which is a reference to a list where each element is a Workspace.typename
remove_types has a value which is a reference to a list where each element is a Workspace.typename
dependencies has a value which is a reference to a hash where the key is a Workspace.modulename and the value is a Workspace.spec_version
dryrun has a value which is a Workspace.boolean
prev_ver has a value which is a Workspace.spec_version


=end text

=back



=head2 RegisterTypespecCopyParams

=over 4



=item Description

Parameters for the register_typespec_copy function.

        Required arguments:
        string external_workspace_url - the URL of the  workspace server from
                which to copy a typespec.
        modulename mod - the name of the module in the workspace server
        
        Optional arguments:
        spec_version version - the version of the module in the workspace
                server


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
external_workspace_url has a value which is a string
mod has a value which is a Workspace.modulename
version has a value which is a Workspace.spec_version

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
external_workspace_url has a value which is a string
mod has a value which is a Workspace.modulename
version has a value which is a Workspace.spec_version


=end text

=back



=head2 ListModulesParams

=over 4



=item Description

Parameters for the list_modules() function.

        Optional arguments:
        username owner - only list modules owned by this user.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
owner has a value which is a Workspace.username

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
owner has a value which is a Workspace.username


=end text

=back



=head2 ListModuleVersionsParams

=over 4



=item Description

Parameters for the list_module_versions function.

        Required arguments:
        One of:
        modulename mod - returns all versions of the module.
        type_string type - returns all versions of the module associated with
                the type.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
mod has a value which is a Workspace.modulename
type has a value which is a Workspace.type_string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
mod has a value which is a Workspace.modulename
type has a value which is a Workspace.type_string


=end text

=back



=head2 ModuleVersions

=over 4



=item Description

A set of versions from a module.

        modulename mod - the name of the module.
        list<spec_version> - a set or subset of versions associated with the
                module.
        list<spec_version> - a set or subset of released versions associated 
                with the module.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
mod has a value which is a Workspace.modulename
vers has a value which is a reference to a list where each element is a Workspace.spec_version
released_vers has a value which is a reference to a list where each element is a Workspace.spec_version

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
mod has a value which is a Workspace.modulename
vers has a value which is a reference to a list where each element is a Workspace.spec_version
released_vers has a value which is a reference to a list where each element is a Workspace.spec_version


=end text

=back



=head2 GetModuleInfoParams

=over 4



=item Description

Parameters for the get_module_info function.

        Required arguments:
        modulename mod - the name of the module to retrieve.
        
        Optional arguments:
        spec_version ver - the version of the module to retrieve. Defaults to
                the latest version.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
mod has a value which is a Workspace.modulename
ver has a value which is a Workspace.spec_version

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
mod has a value which is a Workspace.modulename
ver has a value which is a Workspace.spec_version


=end text

=back



=head2 ModuleInfo

=over 4



=item Description

Information about a module.

        list<username> owners - the owners of the module.
        spec_version ver - the version of the module.
        typespec spec - the typespec.
        string description - the description of the module from the typespec.
        mapping<type_string, jsonschema> types - the types associated with this
                module and their JSON schema.
        mapping<modulename, spec_version> included_spec_version - names of 
                included modules associated with their versions.
        string chsum - the md5 checksum of the object.
        list<func_string> functions - list of names of functions registered in spec.
        boolean is_released - shows if this version of module was released (and
                hence can be seen by others).


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
owners has a value which is a reference to a list where each element is a Workspace.username
ver has a value which is a Workspace.spec_version
spec has a value which is a Workspace.typespec
description has a value which is a string
types has a value which is a reference to a hash where the key is a Workspace.type_string and the value is a Workspace.jsonschema
included_spec_version has a value which is a reference to a hash where the key is a Workspace.modulename and the value is a Workspace.spec_version
chsum has a value which is a string
functions has a value which is a reference to a list where each element is a Workspace.func_string
is_released has a value which is a Workspace.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
owners has a value which is a reference to a list where each element is a Workspace.username
ver has a value which is a Workspace.spec_version
spec has a value which is a Workspace.typespec
description has a value which is a string
types has a value which is a reference to a hash where the key is a Workspace.type_string and the value is a Workspace.jsonschema
included_spec_version has a value which is a reference to a hash where the key is a Workspace.modulename and the value is a Workspace.spec_version
chsum has a value which is a string
functions has a value which is a reference to a list where each element is a Workspace.func_string
is_released has a value which is a Workspace.boolean


=end text

=back



=head2 TypeInfo

=over 4



=item Description

Information about a type

        type_string type_def - resolved type definition id.
        string description - the description of the type from spec file.
        string spec_def - reconstruction of type definition from spec file.
        jsonschema json_schema - JSON schema of this type.
        string parsing_structure - json document describing parsing structure of type 
                in spec file including involved sub-types.
        list<spec_version> module_vers - versions of spec-files containing
                given type version.
        list<spec_version> released_module_vers - versions of released spec-files 
                containing given type version.
        list<type_string> type_vers - all versions of type with given type name.
        list<type_string> released_type_vers - all released versions of type with 
                given type name.
        list<func_string> using_func_defs - list of functions (with versions)
                referring to this type version.
        list<type_string> using_type_defs - list of types (with versions)
                referring to this type version.
        list<type_string> used_type_defs - list of types (with versions) 
                referred from this type version.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
type_def has a value which is a Workspace.type_string
description has a value which is a string
spec_def has a value which is a string
json_schema has a value which is a Workspace.jsonschema
parsing_structure has a value which is a string
module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
released_module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
type_vers has a value which is a reference to a list where each element is a Workspace.type_string
released_type_vers has a value which is a reference to a list where each element is a Workspace.type_string
using_func_defs has a value which is a reference to a list where each element is a Workspace.func_string
using_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
used_type_defs has a value which is a reference to a list where each element is a Workspace.type_string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
type_def has a value which is a Workspace.type_string
description has a value which is a string
spec_def has a value which is a string
json_schema has a value which is a Workspace.jsonschema
parsing_structure has a value which is a string
module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
released_module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
type_vers has a value which is a reference to a list where each element is a Workspace.type_string
released_type_vers has a value which is a reference to a list where each element is a Workspace.type_string
using_func_defs has a value which is a reference to a list where each element is a Workspace.func_string
using_type_defs has a value which is a reference to a list where each element is a Workspace.type_string
used_type_defs has a value which is a reference to a list where each element is a Workspace.type_string


=end text

=back



=head2 FuncInfo

=over 4



=item Description

Information about a function

        func_string func_def - resolved func definition id.
        string description - the description of the function from spec file.
        string spec_def - reconstruction of function definition from spec file.
        string parsing_structure - json document describing parsing structure of function 
                in spec file including types of arguments.
        list<spec_version> module_vers - versions of spec files containing
                given func version.
        list<spec_version> released_module_vers - released versions of spec files 
                containing given func version.
        list<func_string> func_vers - all versions of function with given type
                name.
        list<func_string> released_func_vers - all released versions of function 
                with given type name.
        list<type_string> used_type_defs - list of types (with versions) 
                referred to from this function version.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
func_def has a value which is a Workspace.func_string
description has a value which is a string
spec_def has a value which is a string
parsing_structure has a value which is a string
module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
released_module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
func_vers has a value which is a reference to a list where each element is a Workspace.func_string
released_func_vers has a value which is a reference to a list where each element is a Workspace.func_string
used_type_defs has a value which is a reference to a list where each element is a Workspace.type_string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
func_def has a value which is a Workspace.func_string
description has a value which is a string
spec_def has a value which is a string
parsing_structure has a value which is a string
module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
released_module_vers has a value which is a reference to a list where each element is a Workspace.spec_version
func_vers has a value which is a reference to a list where each element is a Workspace.func_string
released_func_vers has a value which is a reference to a list where each element is a Workspace.func_string
used_type_defs has a value which is a reference to a list where each element is a Workspace.type_string


=end text

=back



=head2 GrantModuleOwnershipParams

=over 4



=item Description

Parameters for the grant_module_ownership function.

Required arguments:
modulename mod - the module to modify.
username new_owner - the user to add to the module's list of
        owners.

Optional arguments:
boolean with_grant_option - true to allow the user to add owners
        to the module.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
mod has a value which is a Workspace.modulename
new_owner has a value which is a Workspace.username
with_grant_option has a value which is a Workspace.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
mod has a value which is a Workspace.modulename
new_owner has a value which is a Workspace.username
with_grant_option has a value which is a Workspace.boolean


=end text

=back



=head2 RemoveModuleOwnershipParams

=over 4



=item Description

Parameters for the remove_module_ownership function.

Required arguments:
modulename mod - the module to modify.
username old_owner - the user to remove from the module's list of
        owners.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
mod has a value which is a Workspace.modulename
old_owner has a value which is a Workspace.username

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
mod has a value which is a Workspace.modulename
old_owner has a value which is a Workspace.username


=end text

=back



=head2 ListAllTypesParams

=over 4



=item Description

Parameters for list_all_types function.

Optional arguments:
boolean with_empty_modules - include empty module names, optional flag,
        default value is false.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
with_empty_modules has a value which is a Workspace.boolean

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
with_empty_modules has a value which is a Workspace.boolean


=end text

=back



=cut

package Workspace::WorkspaceClient::RpcClient;
use base 'JSON::RPC::Client';
use POSIX;
use strict;

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $headers, $obj) = @_;
    my $result;


    {
	if ($uri =~ /\?/) {
	    $result = $self->_get($uri);
	}
	else {
	    Carp::croak "not hashref." unless (ref $obj eq 'HASH');
	    $result = $self->_post($uri, $headers, $obj);
	}

    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $headers, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        # $obj->{id} = $self->id if (defined $self->id);
	# Assign a random number to the id if one hasn't been set
	$obj->{id} = (defined $self->id) ? $self->id : substr(rand(),2);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	@$headers,
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
