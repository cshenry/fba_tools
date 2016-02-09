########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::GapgenerationSolutionReaction - This is the moose object corresponding to the GapgenSolutionReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-08-07T07:31:48
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::GapgenerationSolutionReaction;
package Bio::KBase::ObjectAPI::KBaseFBA::GapgenerationSolutionReaction;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::GapgenerationSolutionReaction';
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
