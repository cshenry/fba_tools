########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::BiochemistryStructures - This is the moose object corresponding to the BiochemistryStructures object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-09-11T20:47:01
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseBiochem::DB::BiochemistryStructures;
package Bio::KBase::ObjectAPI::KBaseBiochem::BiochemistryStructures;
use Moose;
use Bio::KBase::ObjectAPI::utilities;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseBiochem::DB::BiochemistryStructures';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************


#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************



#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 getCreateStructure

Definition:
	Bio::KBase::ObjectAPI::Structure = getCreateStructure({
		data => string:structure data*
		type => string:type of structure*
	});
Description:
	Adds the specified structure to the BiochemistryStructures
	
=cut

sub getCreateStructure {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args( ["data","type"], {}, @_);
	my $structure = $self->queryObject("structures",{
		type => $args->{type},
		data => $args->{data}
	});
	if (!defined($structure)) {
		$structure = $self->add("structures",{
			type => $args->{type},
			data => $args->{data}
		});
	}
	return $structure;
}

__PACKAGE__->meta->make_immutable;
1;
