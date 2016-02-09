########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::Domain - This is the moose object corresponding to the KBaseGenomes.Domain object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-04-15T17:10:03
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseGenomes::DB::Domain;
package Bio::KBase::ObjectAPI::KBaseGenomes::Domain;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseGenomes::DB::Domain';
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
