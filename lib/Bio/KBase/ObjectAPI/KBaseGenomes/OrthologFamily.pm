########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::OrthologFamily - This is the moose object corresponding to the KBaseGenomes.OrthologFamily object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-06-23T19:05:06
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseGenomes::DB::OrthologFamily;
package Bio::KBase::ObjectAPI::KBaseGenomes::OrthologFamily;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseGenomes::DB::OrthologFamily';
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
