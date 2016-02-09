########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::MediaReagent - This is the moose object corresponding to the KBaseBiochem.MediaReagent object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-09-18T19:13:52
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseBiochem::DB::MediaReagent;
package Bio::KBase::ObjectAPI::KBaseBiochem::MediaReagent;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseBiochem::DB::MediaReagent';
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
