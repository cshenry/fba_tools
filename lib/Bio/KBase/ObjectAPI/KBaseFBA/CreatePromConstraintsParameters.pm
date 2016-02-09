########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::CreatePromConstraintsParameters - This is the moose object corresponding to the KBaseFBA.CreatePromConstraintsParameters object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-06-23T19:56:38
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::CreatePromConstraintsParameters;
package Bio::KBase::ObjectAPI::KBaseFBA::CreatePromConstraintsParameters;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::CreatePromConstraintsParameters';
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
