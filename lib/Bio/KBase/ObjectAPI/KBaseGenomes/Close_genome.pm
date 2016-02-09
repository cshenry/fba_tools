########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::Close_genome - This is the moose object corresponding to the KBaseGenomes.Close_genome object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-06-23T03:40:28
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseGenomes::DB::Close_genome;
package Bio::KBase::ObjectAPI::KBaseGenomes::Close_genome;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseGenomes::DB::Close_genome';
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
