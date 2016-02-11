########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::FBAComparison - This is the moose object corresponding to the KBaseFBA.FBAComparison object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2015-07-29T16:48:08
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAComparison;
package Bio::KBase::ObjectAPI::KBaseFBA::FBAComparison;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAComparison';
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
