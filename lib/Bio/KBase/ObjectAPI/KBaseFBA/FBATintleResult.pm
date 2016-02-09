########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::FBATintleResult - This is the moose object corresponding to the KBaseFBA.FBATintleResult object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-06-16T18:50:58
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::FBATintleResult;
package Bio::KBase::ObjectAPI::KBaseFBA::FBATintleResult;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::FBATintleResult';
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
