########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::ClassifierClasses - This is the moose object corresponding to the KBaseFBA.ClassifierClasses object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-08-26T21:34:17
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::ClassifierClasses;
package Bio::KBase::ObjectAPI::KBaseFBA::ClassifierClasses;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::ClassifierClasses';
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
