########################################################################
# Bio::KBase::ObjectAPI::ProbabilisticAnnotation::ProbAnno - This is the moose object corresponding to the ProbabilisticAnnotation.ProbAnno object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-02-19T23:15:57
########################################################################
use strict;
use Bio::KBase::ObjectAPI::ProbabilisticAnnotation::DB::ProbAnno;
package Bio::KBase::ObjectAPI::ProbabilisticAnnotation::ProbAnno;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::ProbabilisticAnnotation::DB::ProbAnno';
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
