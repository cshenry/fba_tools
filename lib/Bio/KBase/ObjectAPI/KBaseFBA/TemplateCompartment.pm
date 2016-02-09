########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompartment - This is the moose object corresponding to the KBaseFBA.TemplateCompartment object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2015-10-16T03:20:25
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateCompartment;
package Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompartment;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateCompartment';
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
