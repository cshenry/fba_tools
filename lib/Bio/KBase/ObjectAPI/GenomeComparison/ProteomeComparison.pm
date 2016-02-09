########################################################################
# Bio::KBase::ObjectAPI::GenomeComparison::ProteomeComparison - This is the moose object corresponding to the GenomeComparison.ProteomeComparison object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-06-17T05:19:37
########################################################################
use strict;
use Bio::KBase::ObjectAPI::GenomeComparison::DB::ProteomeComparison;
package Bio::KBase::ObjectAPI::GenomeComparison::ProteomeComparison;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::GenomeComparison::DB::ProteomeComparison';
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
