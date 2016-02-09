########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::GenomeComparisonFunction - This is the moose object corresponding to the KBaseGenomes.GenomeComparisonFunction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-07-23T23:56:13
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseGenomes::DB::GenomeComparisonFunction;
package Bio::KBase::ObjectAPI::KBaseGenomes::GenomeComparisonFunction;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseGenomes::DB::GenomeComparisonFunction';
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
