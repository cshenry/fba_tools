########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::ModelQuantOpt - This is the moose object corresponding to the KBaseFBA.ModelQuantOpt object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2015-02-02T23:20:04
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelQuantOpt;
package Bio::KBase::ObjectAPI::KBaseFBA::ModelQuantOpt;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelQuantOpt';
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
