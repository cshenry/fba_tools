########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::MapReactionReactant - This is the moose object corresponding to the KBaseBiochem.MapReactionReactant object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-04-03T08:19:18
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseBiochem::DB::MapReactionReactant;
package Bio::KBase::ObjectAPI::KBaseBiochem::MapReactionReactant;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseBiochem::DB::MapReactionReactant';
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
