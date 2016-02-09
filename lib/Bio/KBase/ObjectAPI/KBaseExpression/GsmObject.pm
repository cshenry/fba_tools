########################################################################
# Bio::KBase::ObjectAPI::KBaseExpression::GsmObject - This is the moose object corresponding to the KBaseExpression.GsmObject object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-06-20T19:27:36
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseExpression::DB::GsmObject;
package Bio::KBase::ObjectAPI::KBaseExpression::GsmObject;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseExpression::DB::GsmObject';
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
