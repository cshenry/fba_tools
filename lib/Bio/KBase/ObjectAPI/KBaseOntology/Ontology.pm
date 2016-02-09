########################################################################
# Bio::KBase::ObjectAPI::KBaseOntology::Ontology - This is the moose object corresponding to the KBaseOntology.Ontology object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-02-10T06:01:33
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseOntology::DB::Ontology;
package Bio::KBase::ObjectAPI::KBaseOntology::Ontology;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseOntology::DB::Ontology';
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
