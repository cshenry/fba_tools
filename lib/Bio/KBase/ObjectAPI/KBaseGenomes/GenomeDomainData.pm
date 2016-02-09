########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::GenomeDomainData - This is the moose object corresponding to the KBaseGenomes.GenomeDomainData object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-04-15T17:10:03
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseGenomes::DB::GenomeDomainData;
package Bio::KBase::ObjectAPI::KBaseGenomes::GenomeDomainData;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseGenomes::DB::GenomeDomainData';
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
