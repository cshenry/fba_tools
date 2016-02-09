########################################################################
# Bio::KBase::ObjectAPI::KBaseExpression::ExpressionSeries - This is the moose object corresponding to the KBaseExpression.ExpressionSeries object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-06-20T19:27:36
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseExpression::DB::ExpressionSeries;
package Bio::KBase::ObjectAPI::KBaseExpression::ExpressionSeries;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseExpression::DB::ExpressionSeries';
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
