########################################################################
# Bio::KBase::ObjectAPI::KBaseRegulation::RegulatorySite - This is the moose object corresponding to the KBaseRegulation.RegulatorySite object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-06-20T20:04:53
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseRegulation::DB::RegulatorySite;
package Bio::KBase::ObjectAPI::KBaseRegulation::RegulatorySite;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseRegulation::DB::RegulatorySite';
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
