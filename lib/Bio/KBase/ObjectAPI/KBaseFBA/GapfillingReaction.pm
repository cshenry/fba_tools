########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::GapfillingReaction - This is the moose object corresponding to the GapfillingSolutionReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-05-25T05:08:47
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::GapfillingReaction;
package Bio::KBase::ObjectAPI::KBaseFBA::GapfillingReaction;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::GapfillingReaction';
# CONSTANTS:
#TODO
# FUNCTIONS:
#TODO


__PACKAGE__->meta->make_immutable;
1;
