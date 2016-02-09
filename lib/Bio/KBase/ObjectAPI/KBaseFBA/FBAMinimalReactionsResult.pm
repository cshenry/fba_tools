########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::FBAMinimalReactionsResult - This is the moose object corresponding to the KBaseFBA.FBAMinimalReactionsResult object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-04-21T05:10:55
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAMinimalReactionsResult;
package Bio::KBase::ObjectAPI::KBaseFBA::FBAMinimalReactionsResult;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::FBAMinimalReactionsResult';
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
