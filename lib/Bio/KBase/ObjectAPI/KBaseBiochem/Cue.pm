########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::Cue - This is the moose object corresponding to the Cue object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-04-05T03:44:17
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseBiochem::DB::Cue;
package Bio::KBase::ObjectAPI::KBaseBiochem::Cue;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseBiochem::DB::Cue';
# CONSTANTS:
#TODO
# FUNCTIONS:
#TODO


__PACKAGE__->meta->make_immutable;
1;
