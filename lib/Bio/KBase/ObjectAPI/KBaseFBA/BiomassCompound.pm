########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::BiomassCompound - This is the moose object corresponding to the BiomassCompound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::BiomassCompound;
package Bio::KBase::ObjectAPI::KBaseFBA::BiomassCompound;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::BiomassCompound';
# CONSTANTS:
#TODO
# FUNCTIONS:
#TODO


__PACKAGE__->meta->make_immutable;
1;
