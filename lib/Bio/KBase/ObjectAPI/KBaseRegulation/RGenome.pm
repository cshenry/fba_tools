########################################################################
# Bio::KBase::ObjectAPI::KBaseRegulation::RGenome - This is the moose object corresponding to the KBaseRegulation.RGenome object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-06-20T21:48:48
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseRegulation::DB::RGenome;
package Bio::KBase::ObjectAPI::KBaseRegulation::RGenome;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseRegulation::DB::RGenome';
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
