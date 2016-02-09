########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::TintleProbabilitySample - This is the moose object corresponding to the KBaseFBA.TintleProbabilitySample object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-06-13T15:15:08
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::TintleProbabilitySample;
package Bio::KBase::ObjectAPI::KBaseFBA::TintleProbabilitySample;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::TintleProbabilitySample';
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
