########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::FBAComparisonReaction - This is the moose object corresponding to the KBaseFBA.FBAComparisonReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2015-07-29T16:48:08
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAComparisonReaction;
package Bio::KBase::ObjectAPI::KBaseFBA::FBAComparisonReaction;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAComparisonReaction';
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


__PACKAGE__->meta->make_immutable;
1;
