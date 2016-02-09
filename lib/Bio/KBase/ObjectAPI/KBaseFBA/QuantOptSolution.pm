########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::QuantOptSolution - This is the moose object corresponding to the KBaseFBA.QuantOptSolution object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2015-02-02T23:20:04
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::QuantOptSolution;
package Bio::KBase::ObjectAPI::KBaseFBA::QuantOptSolution;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::QuantOptSolution';
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
