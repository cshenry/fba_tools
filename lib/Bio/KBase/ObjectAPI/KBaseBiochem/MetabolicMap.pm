########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::MetabolicMap - This is the moose object corresponding to the KBaseBiochem.MetabolicMap object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-02-19T23:11:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseBiochem::DB::MetabolicMap;
package Bio::KBase::ObjectAPI::KBaseBiochem::MetabolicMap;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseBiochem::DB::MetabolicMap';
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
