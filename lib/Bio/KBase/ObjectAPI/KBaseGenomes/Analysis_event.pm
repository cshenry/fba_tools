########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::Analysis_event - This is the moose object corresponding to the KBaseGenomes.Analysis_event object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-06-23T03:40:28
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseGenomes::DB::Analysis_event;
package Bio::KBase::ObjectAPI::KBaseGenomes::Analysis_event;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseGenomes::DB::Analysis_event';
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
