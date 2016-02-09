########################################################################
# Bio::KBase::ObjectAPI::KBaseExpression::Protocol - This is the moose object corresponding to the KBaseExpression.Protocol object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-06-20T19:27:36
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseExpression::DB::Protocol;
package Bio::KBase::ObjectAPI::KBaseExpression::Protocol;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseExpression::DB::Protocol';
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
