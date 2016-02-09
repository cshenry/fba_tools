########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::TemplateSubsystem - This is the moose object corresponding to the KBaseFBA.TemplateSubsystem object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2015-11-12T04:56:41
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateSubsystem;
package Bio::KBase::ObjectAPI::KBaseFBA::TemplateSubsystem;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateSubsystem';
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
