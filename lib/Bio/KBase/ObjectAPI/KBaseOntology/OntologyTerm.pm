########################################################################
# Bio::KBase::ObjectAPI::KBaseOntology::OntologyTerm - This is the moose object corresponding to the KBaseOntology.OntologyTerm object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-07-23T06:10:57
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseOntology::DB::OntologyTerm;
package Bio::KBase::ObjectAPI::KBaseOntology::OntologyTerm;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseOntology::DB::OntologyTerm';
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
