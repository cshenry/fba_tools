########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::MetagenomeAnnotation - This is the moose object corresponding to the KBaseGenomes.MetagenomeAnnotation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-01-31T17:18:43
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseGenomes::DB::MetagenomeAnnotation;
package Bio::KBase::ObjectAPI::KBaseGenomes::MetagenomeAnnotation;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseGenomes::DB::MetagenomeAnnotation';
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
