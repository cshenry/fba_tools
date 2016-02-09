########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::ActivatedReaction - This is the moose object corresponding to the KBaseFBA.ActivatedReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-08-23T07:30:46
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::ActivatedReaction;
package Bio::KBase::ObjectAPI::KBaseFBA::ActivatedReaction;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::ActivatedReaction';
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
