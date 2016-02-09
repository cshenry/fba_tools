########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::ContigSet - This is the moose object corresponding to the KBaseGenomes.ContigSet object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-01-05T15:36:51
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseGenomes::DB::ContigSet;
package Bio::KBase::ObjectAPI::KBaseGenomes::ContigSet;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseGenomes::DB::ContigSet';
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
