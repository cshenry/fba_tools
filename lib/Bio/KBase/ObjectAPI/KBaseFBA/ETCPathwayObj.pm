########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::ETCPathwayObj - This is the moose object corresponding to the KBaseFBA.ETCPathwayObj object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-05-13T20:12:44
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::ETCPathwayObj;
package Bio::KBase::ObjectAPI::KBaseFBA::ETCPathwayObj;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::ETCPathwayObj';
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
