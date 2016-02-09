########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::ReactionGroup - This is the moose object corresponding to the KBaseBiochem.ReactionGroup object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-04-15T17:10:03
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseBiochem::DB::ReactionGroup;
package Bio::KBase::ObjectAPI::KBaseBiochem::ReactionGroup;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseBiochem::DB::ReactionGroup';
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
