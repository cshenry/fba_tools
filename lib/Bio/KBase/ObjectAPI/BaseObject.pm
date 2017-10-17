########################################################################
# Bio::KBase::ObjectAPI::BaseObject - This is a base object that serves as a foundation for all other objects
# Author: Christopher Henry
# Author email: chenry@mcs.anl.gov
# Author affiliation: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 3/11/2012
########################################################################
use Bio::KBase::ObjectAPI::Types;
use DateTime;
use Data::UUID;
use JSON::XS;
use Module::Load;
use Bio::KBase::ObjectAPI::Attribute::Typed;
use Bio::KBase::ObjectAPI::Exceptions;
use Bio::KBase::ObjectAPI::utilities;
package Bio::KBase::ObjectAPI::BaseObject;

=head1 Bio::KBase::ObjectAPI::BaseObject

=head2 SYNOPSIS

=head2 METHODS

=head3 Initialization

=head4 new

    my $obj = Bio::KBase::ObjectAPI::Object->new();   # Initialize object with default parameters
    my $obj = Bio::KBase::ObjectAPI::Object->new(\%); # Initialize object with hashref of parameters
    my $obj = Bio::KBase::ObjectAPI::Object->new(%);  # Initialize object with hash of parameters

=head3 Serialization

=head4 serializeToDB

Return a simple perl hash that can be passed to a JSON serializer.

    my $data = $object->serializeToDB();

=head4 toJSON

    my $string = $object->toJSON(\%);

Serialize object to JSON. A hash reference of options may be passed
as the first argument. Currently only one option is available C<pp>
which will pretty-print the ouptut.

=head4 createHTML

    my $string = $object->createHTML();

Returns an HTML document for the object.

=head4 toReadableString

    my $string = $object->toReadableString();

=head3 Object Traversal

=head4 defaultNameSpace

=head4 getLinkedObject

=head4 getLinkedObjectArray

=head4 store

=head4 biochemisry

=head4 annotation

=head4 mapping

=head4 fbaproblem

=head3 Object Manipulation

=head4 add

=head4 remove

=head3 Helper Functions

=head4 interpretReference

=head4 parseReferenceList

=head3 Schema Versioning

=head4 __version__

=head4 __upgrade__

=cut

use Moose;
use namespace::autoclean;
use Scalar::Util qw(weaken);
our $VERSION = undef;

has jobresult => ( is => 'rw', isa => 'HashRef', default => sub { return {} } );

my $htmlheader = <<HEADER;
<!doctype HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>\${TITLE}</title>
<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css">
<link rel="stylesheet" href="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/css/jquery.dataTables.css">
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
<script src="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
<script type="text/javascript" charset="utf8" src="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/jquery.dataTables.js"></script>
<script type="text/javascript">
  \$(document).ready(function() {
    \$('#tab-header a').click(function (e) {
      e.preventDefault();
      \$(this).tab('show');
    });

    \$('.data-table').dataTable();
  });
</script>
<style type="text/css">
    #tabs {
        margin: 20px 50px;
    }
</style>
</head>
HEADER

my $htmlbody = <<BODY;
<body>
<div id="tabs">
<ul class="nav nav-tabs" id="tab-header">
<li class="active"><a href="#tab-1">Overview</a></li>
\${TABS}
</ul>
<div class="tab-content">
<div class="tab-pane active" id="tab-1">
\${MAINTAB}
</div>
\${TABDIVS}
</div>
</div>
</body>
BODY

my $htmltail = <<TAIL;
</html>
TAIL

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $hash = {};
    if ( ref $_[0] eq 'HASH' ) {
        $hash = shift;    
    } elsif ( scalar @_ % 2 == 0 ) {
        my %h = @_;
        $hash = \%h;
    }
    my $objVersion = $hash->{__VERSION__};
    my $classVersion = $class->__version__;
    if (!defined($objVersion) && defined($hash->{parent})) {
    	$objVersion = 1;
    }
    if (defined $objVersion && defined($classVersion) && $objVersion != $classVersion) {
        if (defined(my $fn = $class->__upgrade__($objVersion))) {
            $hash = $fn->($hash);
        } else {
            die "Invalid Object\n";
        }
    }   

    my $sos = $class->_subobjects();
    foreach my $subobj (@{$sos}) {
        if (defined($subobj->{singleton}) && $subobj->{singleton} == 1) {
	    if (defined $hash->{$subobj->{name}}) {
		$hash->{$subobj->{name}} = [$hash->{$subobj->{name}}];
	    }
	    else {
		$hash->{$subobj->{name}} = [];
	    }
        }
    }

    return $class->$orig($hash);
};


sub BUILD {
    my ($self,$params) = @_;
    # replace subobject data with info hash
    foreach my $subobj (@{$self->_subobjects}) {
        my $name = $subobj->{name};
        my $class = $subobj->{class};
        my $method = "_$name";
        my $subobjs = $self->$method();

        for (my $i=0; $i<scalar @$subobjs; $i++) {
            my $data = $subobjs->[$i];
            # create the info hash
            my $info = {
                created => 0,
                class   => $class,
                data    => $data
            };

            $data->{parent} = $self; # set the parent
            weaken($data->{parent}); # and make it weak
            $subobjs->[$i] = $info; # reset the subobject with info hash
        }
    }
}

sub ref_chain {
	my ($self,$ref) = @_;
	if (defined($ref)) {
		$self->{_ref_chain} = $ref;
	}
	if (!defined($self->{_ref_chain})) {
		$self->{_ref_chain} = "";
	}
	return $self->{_ref_chain};
}

sub fix_reference {
	my ($self,$ref) = @_;
	# can't use "self" in refpaths
	$ref =~ s/^~;//;
	if ($ref =~ m/^~/) {
		return $ref;
	} elsif ($ref =~ m/^([A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12})/) {
		my $uuid = $1;
		if ($self->topparent()->uuid() eq $uuid) {
			$ref =~ s/$uuid/~/;
			return $ref;
		}
		my $newref = $self->store()->uuid_to_ref($uuid);
		if (!defined($newref)) {
			Bio::KBase::ObjectAPI::utilities::error("Attempting to save object with references to unsaved object:".$uuid);
		}
		$ref =~ s/$uuid/$newref/;
		return $ref;
	} elsif ($ref =~ m/^(\w+\/\w+\/\w+)\//) {
		my $oldref = $1;
		my $newref = $self->store()->updated_reference($oldref);
		if (!defined($newref)) {
			$newref = $oldref;
		}
		if ($self->topparent()->_reference() eq $newref) {
			$ref =~ s/$oldref/~/;
		} elsif ($newref ne $oldref) {
			$ref =~ s/$oldref/$newref/;
		}
		return $ref;
	}
	return $ref;
}

sub fix_references {
	my ($self) = @_;
	my $links = $self->_links();
	foreach my $link (@{$links}) {
		my $att = $link->{attribute};
		if (defined($self->$att())) {
			if (defined($link->{array})) {
				my $refarray = $self->$att();
				for (my $i=0; $i < @{$refarray}; $i++) {
					$self->$att()->[$i] = $self->fix_reference($self->$att()->[$i]);
				}
			} else {
				$self->$att($self->fix_reference($self->$att()));
			}
		}	
	}
}

sub serializeToDB {
    my ($self) = @_;
    my $data = {};
	$self->fix_references();
	if ($self->can('translate_to_localrefs')) {
		print("Converting to local references\n");
		$self->translate_to_localrefs();
	}
	$data = { __VERSION__ => $self->__version__() } if defined $self->__version__();
    my $attributes = $self->_attributes();
    foreach my $item (@{$attributes}) {
    	my $name = $item->{name};
    	if ($name eq "isCofactor") {
    		if ($self->$name() != 0 && $self->$name() != 1) {
				$self->$name(0);
    		}
    	}
		if (defined($self->$name())) {
			if ($item->{type} eq "Int" || $item->{type} eq "Num" || $item->{type} eq "Bool") {
				$data->{$name} = $self->$name()+0;
			} elsif ($name eq "fba_ref" || $name eq "gapfill_ref") {
				if (defined($self->$name()) && length($self->$name()) > 0) {
					$data->{$name} = $self->$name();
				}
			} elsif ($name eq "cues") {
				$data->{$name} = $self->$name();
				foreach my $cue (keys(%{$data->{$name}})) {
					$data->{$name}->{$cue} = $data->{$name}->{$cue}+0;
				}
			} elsif ($name =~ m/_objterms$/) {
				$data->{$name} = {};
				foreach my $key (keys(%{$self->$name()})) {
					$data->{$name}->{$key} = $self->$name()->{$key}+0;
				}
			} elsif ($name =~ m/uptakeLimits/) {
				$data->{$name} = {};
				foreach my $key (keys(%{$self->$name()})) {
					$data->{$name}->{$key} = $self->$name()->{$key}+0;
				}
			} elsif ($name =~ m/minimize_reaction_costs/) {
				$data->{$name} = {};
				foreach my $key (keys(%{$self->$name()})) {
					$data->{$name}->{$key} = $self->$name()->{$key}+0;
				}
			} elsif ($name =~ m/^parameters$/) {
				$data->{$name} = {};
				foreach my $key (keys(%{$self->$name()})) {
					$data->{$name}->{$key} = $self->$name()->{$key}."";
				}
			} elsif ($name eq "annotations") {
				my $dataitem = $self->$name();
				for (my $i=0; $i < @{$dataitem}; $i++) {
					if (!defined($dataitem->[$i]->[1])) {
						$data->{$name}->[$i]->[1] = "";
					} else {
						$data->{$name}->[$i]->[1] = $dataitem->[$i]->[1];
					}
					if (!defined($dataitem->[$i]->[0])) {
						$data->{$name}->[$i]->[0] = "";
					} else {
						$data->{$name}->[$i]->[0] = $dataitem->[$i]->[0];
					}
					$data->{$name}->[$i]->[2] = $dataitem->[$i]->[2]+0;
				}
			} elsif ($name eq "location") {
				my $dataitem = $self->$name();
				for (my $i=0; $i < @{$dataitem}; $i++) {
					$data->{$name}->[$i]->[0] = $dataitem->[$i]->[0];
					$data->{$name}->[$i]->[1] = $dataitem->[$i]->[1]+0;
					$data->{$name}->[$i]->[3] = $dataitem->[$i]->[3]+0;
					$data->{$name}->[$i]->[2] = $dataitem->[$i]->[2];
				}
			} else {
    			$data->{$name} = $self->$name();
			}	
    	}
    }
    my $subobjects = $self->_subobjects();
    foreach my $item (@{$subobjects}) {
    	my $name = "_".$item->{name};
    	my $arrayRef = $self->$name();
		$data->{$item->{name}} = [];
		foreach my $subobject (@{$arrayRef}) {
		    if ($subobject->{created} == 1) {
				push(@{$data->{$item->{name}}},$subobject->{object}->serializeToDB());	
		    } else {
				my $newData;
				foreach my $key (keys(%{$subobject->{data}})) {
				    if ($key ne "parent") {
						$newData->{$key} = $subobject->{data}->{$key};
				    }
				}
				push(@{$data->{$item->{name}}},$newData);
		    }
		}
		if (defined $item->{"singleton"} && $item->{"singleton"} == 1) {
		    if (scalar @{$data->{$item->{name}}} > 0) {
				$data->{$item->{name}} = $data->{$item->{name}}->[0];
		    } else {
				delete $data->{$item->{name}};
		    }
		}
    }
    return $data;
}

sub cloneObject {
	my ($self) = @_;
	my $data = $self->serializeToDB();
	my $class = "Bio::KBase::ObjectAPI::".$self->_module()."::".$self->_class();
	return $class->new($data);
}

sub toJSON {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args([],{pp => 0}, @_);
    my $data = $self->serializeToDB();
    my $JSON = JSON::XS->new->utf8(1);
    $JSON->allow_blessed(1);
    $JSON->pretty(1) if($args->{pp} == 1);
    return $JSON->encode($data);
}

=head3 export

Definition:
	string = Bio::KBase::ObjectAPI::BaseObject->export({
		format => readable/html/json
	});
Description:
	Exports media data to the specified format.

=cut

sub export {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["format"], {}, @_);
	my $function = "print_".$args->{format};
	if (!$self->can($function)) {
		Bio::KBase::ObjectAPI::utilities::error("Unrecognized type for export: ".$args->{format});
	}
	$self->$function();
}

=head3 print_html

Definition:
	
Description:
	Exports data to html format

=cut

sub print_html {
    my $self = shift;
	return $self->createHTML();
}

=head3 print_readable

Definition:
	
Description:
	Exports data to readable format

=cut

sub print_readable {
    my $self = shift;
	return $self->toReadableString();
}

=head3 print_json

Definition:
	
Description:
	Exports data to json format

=cut

sub print_json {
    my $self = shift;
	return $self->toJSON();
}

######################################################################
#Output functions
######################################################################
sub htmlComponents {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args([],{}, @_);
	my $data = $self->_createReadableData();
	my $output = {
		title => $self->_type()." Viewer",
		tablist => [],
		tabs => {
			main => {
				content => "",
				name => "Overview"
			}
		}
	};
	$output->{tabs}->{main}->{content} .= "<table>\n";
	for (my $i=0; $i < @{$data->{attributes}->{headings}}; $i++) {
		$output->{tabs}->{main}->{content} .= "<tr><th>".$data->{attributes}->{headings}->[$i]."</th><td style='font-size:16px;border: 1px solid black;'>".$data->{attributes}->{data}->[0]->[$i]."</td></tr>\n";
	}
	$output->{tabs}->{main}->{content} .= "</table>\n";
	my $count = 2;
	foreach my $subobject (@{$data->{subobjects}}) {
		my $name = $self->_type()." ".$subobject->{name};
		my $id = "tab-".$count;
		push(@{$output->{tablist}},$id);
		$output->{tabs}->{$id} = {
			content => Bio::KBase::ObjectAPI::utilities::PRINTHTMLTABLE( $subobject->{headings}, $subobject->{data}, 'data-table' ),
			name => $name
		};
		$count++;
	}
	return $output;
}

sub createHTML {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args([],{internal => 0}, @_);
	my $document = "";
	if ($args->{internal} == 0) {
		$document .= $htmlheader."\n";
	}
	$document .= $htmlbody."\n";
	if ($args->{internal} == 0) {
		$document .= $htmltail;
	}
	my $htmlData = $self->htmlComponents();
	my $title = $htmlData->{title};
	$document =~ s/\$\{TITLE\}/$title/;
	my $tablist = "";
	foreach my $id (@{$htmlData->{tablist}}) {
		$tablist .= '<li><a href="#'.$id.'">'.$htmlData->{tabs}->{$id}->{name}."</a></li>\n";
	}
	$document =~ s/\$\{TABS\}/$tablist/;
	my $maintab = $htmlData->{tabs}->{main}->{content};
	$document =~ s/\$\{MAINTAB\}/$maintab/;
	my $divdata = "";
	for (my $i=0; $i < @{$htmlData->{tablist}}; $i++) {
		$divdata .= '<div class="tab-pane" id="'.$htmlData->{tablist}->[$i].'">'."\n";
		$divdata .= $htmlData->{tabs}->{$htmlData->{tablist}->[$i]}->{content};
		$divdata .= "</div>\n";
	}
	$document =~ s/\$\{TABDIVS\}/$divdata/;
	return $document;
}

sub toReadableString {
	my ($self, $asArray) = @_;
	my $output = ["Attributes {"];
	my $data = $self->_createReadableData();
	for (my $i=0; $i < @{$data->{attributes}->{headings}}; $i++) {
		push(@{$output},"\t".$data->{attributes}->{headings}->[$i].":".$data->{attributes}->{data}->[0]->[$i])
	}
	push(@{$output},"}");
	if (defined($data->{subobjects})) {
		for (my $i=0; $i < @{$data->{subobjects}}; $i++) {
			push(@{$output},$data->{subobjects}->[$i]->{name}." (".join("\t",@{$data->{subobjects}->[$i]->{headings}}).") {");
			for (my $j=0; $j < @{$data->{subobjects}->[$i]->{data}}; $j++) {
				push(@{$output},join("\t",@{$data->{subobjects}->[$i]->{data}->[$j]}));
			}
			push(@{$output},"}");
		}
	}
	if (defined($data->{results})) {
		for (my $i=0; $i < @{$data->{results}}; $i++) {
			my $rs = $data->{results}->[$i];
			my $objects = $self->$rs();
			if (defined($objects->[0])) {
				push(@{$output},$rs." objects {");
				for (my $j=0; $j < @{$objects}; $j++) {
					push(@{$output},@{$objects->[$j]->toReadableString("asArray")});
				}
				push(@{$output},"}");
			}
		}
	}
    return join("\n", @$output) unless defined $asArray;
	return $output;
}

sub _createReadableData {
	my ($self) = @_;
	my $data;
	my ($sortedAtt,$sortedSO,$sortedRS) = $self->_getReadableAttributes();
	$data->{attributes}->{headings} = $sortedAtt;
	for (my $i=0; $i < @{$data->{attributes}->{headings}}; $i++) {
		my $att = $data->{attributes}->{headings}->[$i];
		push(@{$data->{attributes}->{data}->[0]},$self->$att());
	}
	for (my $i=0; $i < @{$sortedSO}; $i++) {
		my $so = $sortedSO->[$i];
		my $soData = {name => $so};
		my $objects = $self->$so();
		if (defined($objects->[0])) {
			my ($sortedAtt,$sortedSO) = $objects->[0]->_getReadableAttributes();
			$soData->{headings} = $sortedAtt;
			for (my $j=0; $j < @{$objects}; $j++) {
				for (my $k=0; $k < @{$sortedAtt}; $k++) {
					my $att = $sortedAtt->[$k];
					$soData->{data}->[$j]->[$k] = ($objects->[$j]->$att() || "");
				}
			}
			push(@{$data->{subobjects}},$soData);
		}
	}
	for (my $i=0; $i < @{$sortedRS}; $i++) {
		push(@{$data->{results}},$sortedRS->[$i]);
	}
	return $data;
 }
 
sub _getReadableAttributes {
	my ($self) = @_;
	my $priority = {};
	my $attributes = [];
	my $prioritySO = {};
	my $attributesSO = [];
	my $priorityRS = {};
	my $attributesRS = [];
	my $class = 'Bio::KBase::ObjectAPI::'.$self->_module().'::'.$self->_class();
	foreach my $attr ( $class->meta->get_all_attributes ) {
		if ($attr->isa('Bio::KBase::ObjectAPI::Attribute::Typed') && $attr->printOrder() != -1 && ($attr->type() eq "attribute" || $attr->type() eq "msdata")) {
			push(@{$attributes},$attr->name());
			$priority->{$attr->name()} = $attr->printOrder();
		} elsif ($attr->isa('Bio::KBase::ObjectAPI::Attribute::Typed') && $attr->printOrder() != -1 && $attr->type() =~ m/^result/) {
			push(@{$attributesRS},$attr->name());
			$priorityRS->{$attr->name()} = $attr->printOrder();
		} elsif ($attr->isa('Bio::KBase::ObjectAPI::Attribute::Typed') && $attr->printOrder() != -1) {
			push(@{$attributesSO},$attr->name());
			$prioritySO->{$attr->name()} = $attr->printOrder();
		}
	}
	my $sortedAtt = [sort { $priority->{$a} <=> $priority->{$b} } @{$attributes}];
	my $sortedSO = [sort { $prioritySO->{$a} <=> $prioritySO->{$b} } @{$attributesSO}];
	my $sortedRS = [sort { $priorityRS->{$a} <=> $priorityRS->{$b} } @{$attributesRS}];
	return ($sortedAtt,$sortedSO,$sortedRS);
}
######################################################################
#SubObject manipulation functions
######################################################################

sub add {
    my ($self, $attribute, $data_or_object) = @_;

    my $attr_info = $self->_subobjects($attribute);
    if (!defined($attr_info)) {
        Bio::KBase::ObjectAPI::utilities::error("Object doesn't have subobject with name: $attribute");
    }

    my $obj_info = {
        created => 0,
        class => $attr_info->{class}
    };

    my $ref = ref($data_or_object);
    if ($ref eq "HASH") {
        # need to create object first
        $obj_info->{data} = $data_or_object;
        $self->_build_object($attribute, $obj_info);
    } elsif ($ref =~ m/Bio::KBase::ObjectAPI/) {
        $obj_info->{object} = $data_or_object;
        $obj_info->{created} = 1;
    } else {
        Bio::KBase::ObjectAPI::utilities::error("Neither data nor object passed into " . ref($self) . "->add");
    }

    $obj_info->{object}->parent($self);
    my $method = "_$attribute";
    push(@{$self->$method}, $obj_info);
    return $obj_info->{object};
}

sub remove {
    my ($self, $attribute, $object) = @_;

    my $attr_info = $self->_subobjects($attribute);
    if (!defined($attr_info)) {
        Bio::KBase::ObjectAPI::utilities::error("Object doesn't have attribute with name: $attribute");
    }

    my $removedCount = 0;
    my $method = "_$attribute";
    my $array = $self->$method;
    for (my $i=0; $i<@$array; $i++) {
        my $obj_info = $array->[$i];
        if ($obj_info->{created}) {
            if ($object eq $obj_info->{object}) {
                splice(@$array, $i, 1);
                $removedCount += 1;
            }
        }
    }

    return $removedCount;
}

sub getLinkedObject {
    my ($self, $ref) = @_;
	my $debug = 0;
	my $refchain = $self->ref_chain();
	print("ref: $ref\n") if $debug;
	print("refchain: $refchain\n") if $debug;
	if (length($refchain) > 0) {
		$refchain .= ";";
	}
	if ($ref =~ m/^~$/) {
		print("Branch 1\n") if $debug;
		return $self->topparent();
	} elsif ($ref =~ m/(.+)\|\|(.*)/) {
		print("Branch 2\n") if $debug;
    	my $objpath = $1;
    	my $internalref = $2;
    	if ($objpath !~ m/^\//) {
    		$objpath = $self->topparent()->wsmeta()->[2].$objpath;
    		while ($objpath =~ m/[^\/]+\/\.\.\/*/) {
				$objpath =~ s/[^\/]+\/\.\.\/*//g;
			}
    	}
    	my $obj = $self->store()->get_object($refchain.$objpath);
    	if (length($internalref) == 0) {
    		return $obj;
    	} elsif ($internalref =~ m/^\/(\w+)\/(\w+)\/([\w\.\|\-:]+)$/) {
    		return $obj->queryObject($1,{$2 => $3});
    	}
	} elsif ($ref =~ m/^~\/(\w+)\/(\w+)\/(\w+)\/(\w+)\/([\w\.\|\-:]+)$/) {
		print("Branch 3\n") if $debug;
		my $linkedobject = $1;
		my $otherlinkedobject = $2;
		my $field = $3;
    	my $query = {$4 => $5};
		return $self->topparent()->$linkedobject()->$otherlinkedobject()->queryObject($field,$query);
	} elsif ($ref =~ m/^~\/(\w+)\/(\w+)\/(\w+)\/([\w\.\|\-:]+)$/) {
		print("Branch 4\n") if $debug;
		my $linkedobject = $1;
		my $field = $2;
    	my $query = {$3 => $4};
		return $self->topparent()->$linkedobject()->queryObject($field,$query);
	} elsif ($ref =~ m/^~\/(\w+)\/(\w+)\/([\w\.\|\-:]+)$/) {
		print("Branch 5\n") if $debug;
		return $self->topparent()->queryObject($1,{$2 => $3});
	} elsif ($ref =~ m/^[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}$/) {
		print("Branch 6\n") if $debug;
		return $self->store()->getObjectByUUID($ref);
	} elsif ($ref =~ m/^([A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12})\/(\w+)\/(\w+)\/([\w\.\|\-]+)$/) {
		print("Branch 7\n") if $debug;
		Bio::KBase::ObjectAPI::utilities::error("FAILED!");
	} elsif ($ref =~ m/^[:\w]+\/[\w\.\|\-]+\/[\w\.\|\-]+$/) {
		print("Branch 8\n") if $debug;
    	return $self->store()->get_object($refchain.$ref);
    } elsif ($ref =~ m/^([:\w]+\/\w+\/\w+)\/(\w+)\/(\w+)\/([\w\.\|\-:]+)$/) {
		print("Branch 9\n") if $debug;
    	my $field = $2;
    	my $query = {$3 => $4};
    	my $object = $self->store()->get_object($refchain.$1);
    	return $object->queryObject($field,$query);
    } elsif ($ref =~ m/^[:\w]+\/[\w\.\|\-]+$/) {
		print("Branch 0\n") if $debug;
    	return $self->store()->get_object($refchain.$ref);
    } elsif ($ref =~ m/^([:\w]+\/\w+)\/(\w+)\/(\w+)\/([\w\.\|\-:]+)$/) {
		print("Branch 1\n") if $debug;
    	my $field = $2;
    	my $query = {$3 => $4};
    	my $object = $self->store()->get_object($refchain.$1);
    	return $object->queryObject($field,$query);
	# if refereance is already a ref_chain, stand out of the way
    } elsif ($ref =~ m/^(\d+\/\d+\/\d+;)+\d+\/\d+\/\d+$/) {
		print("Branch 12: Already a ref_chain\n") if $debug;
    	return $self->store()->get_object($ref);
    }
    Bio::KBase::ObjectAPI::utilities::error("Unrecognized reference format:".$ref);
}

sub getLinkedObjectArray {
    my ($self,$array) = @_;
    my $list = [];
    foreach my $item (@{$array}) {
    	push(@{$list},$self->getLinkedObject($item));
    }
    return $list;
}

sub removeLinkArrayItem {
	my ($self,$link,$object) = @_;
    my $linkdata = $self->_links($link);
    if (defined($linkdata) && $linkdata->{array} == 1) {
    	my $method = $linkdata->{attribute};
    	my $data = $self->$method();
    	my $id = $object->id();
    	for (my $i=0; $i < @{$data}; $i++) {
			if ($data->[$i] =~ m/$id$/) {
				Bio::KBase::ObjectAPI::utilities::verbose("Removing object from link array.");
				if (@{$data} == 1) {
					$self->$method([]);
				} else {
					splice(@{$data},$i,1);
					$self->$method($data);
				}
				my $clearer = "clear_".$link;
				$self->$clearer();
			}
		}
    }	
}

sub addLinkArrayItem {
	my ($self,$link,$object) = @_;
    my $linkdata = $self->_links($link);
    if (defined($linkdata) && $linkdata->{array} == 1) {
    	my $method = $linkdata->{attribute};
    	my $data = $self->$method();
    	my $found = 0;
    	my $id = $object->id();
    	for (my $i=0; $i < @{$data}; $i++) {
			if ($data->[$i] =~ m/\Q$id\E$/) {
				$found = 1;
			}
    	}
    	if ($found == 0) {
    		Bio::KBase::ObjectAPI::utilities::verbose("Adding object to link array.");
    		my $clearer = "clear_".$link;
			$self->$clearer();
			push(@{$data},$object->_reference());
    	}
    }	
}

sub clearLinkArray {
	my ($self,$link) = @_;
    my $linkdata = $self->_links($link);
    if (defined($linkdata) && $linkdata->{array} == 1) {
    	my $method = $linkdata->{attribute};
    	$self->$method([]);
    	Bio::KBase::ObjectAPI::utilities::verbose("Clearing link array.");
    	my $clearer = "clear_".$link;
		$self->$clearer();
    }	
}

sub store {
    my ($self) = @_;
    my $parent = $self->parent();
    if (defined($parent) && ref($parent) ne "Bio::KBase::ObjectAPI::KBaseStore" && ref($parent) ne "Bio::KBase::ObjectAPI::PATRICStore" && ref($parent) ne "Bio::KBase::ObjectAPI::FileStore") {
        return $parent->store();
    }
    if (!defined($parent)) {
    	Bio::KBase::ObjectAPI::utilities::error("Attempted to get object with no store!");
    }
    return $parent;
}

sub topparent {
    my ($self) = @_;
    if ($self->_top() == 1) {
    	return $self;
    } else {
    	return $self->parent()->topparent();
    }
}

sub _build_object {
    my ($self, $attribute, $obj_info) = @_;

    if ($obj_info->{created}) {
        return $obj_info->{object};
    }
	my $attInfo = $self->_subobjects($attribute);
    if (!defined($attInfo->{class})) {
    	Bio::KBase::ObjectAPI::utilities::error("No class for attribute ".$attribute);	
    }
    my $class = 'Bio::KBase::ObjectAPI::' . $attInfo->{module} . '::' . $attInfo->{class};
    Module::Load::load $class;
    my $obj = $class->new($obj_info->{data});

    $obj_info->{created} = 1;
    $obj_info->{object} = $obj;
    delete $obj_info->{data};

    return $obj;
}

sub _build_all_objects {
    my ($self, $attribute) = @_;

    my $objs = [];
    my $method = "_$attribute";
    my $subobjs = $self->$method();
    foreach my $subobj (@$subobjs) {
        push(@$objs, $self->_build_object($attribute, $subobj));
    }

    return $objs;
}

sub __version__ { $VERSION }
sub __upgrade__ { return sub { return $_[0] } }

__PACKAGE__->meta->make_immutable;
1;
