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

has reaction => (is => 'rw', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_reaction', clearer => 'clear_reaction', isa => 'Ref', weak_ref => 1);

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _build_reaction {
	 my ($self) = @_;
	 if ($self->reaction_ref() !~ m/_[a-z]/ && $self->reaction_ref() =~ m/\/([^\/]+)$/) {
	 	my $rxnid = $1;
	 	my $comp = "c";
	 	if ($self->compartment_ref() =~ m/\/([^\/]+)$/) {
	 		$comp = $1;
	 	}
	 	$self->reaction_ref("~/fbamodel/template/reactions/id/".$rxnid."_".$comp);
	 }
	 my $rxn = $self->getLinkedObject($self->reaction_ref());
	 if (!defined($rxn)) {
	 	my $ref = $self->reaction_ref();
	 	$ref =~ s/_e/_c/;
	 	$self->reaction_ref($ref);
	 	$rxn = $self->getLinkedObject($self->reaction_ref());
	 }
	 if (!defined($rxn)) {
	 	$rxn = $self->getLinkedObject("~/fbamodel/template/reactions/id/rxn00000_c");
	 	if (!defined($rxn)) {
		 	$rxn = $self->parent()->parent()->fbamodel()->template()->add("reactions",{
		 		id => "rxn00000_c",
				reaction_ref => "~/biochemistry/reactions/id/rxn00000",
		    	name => "CustomReaction",
		    	direction => "=",
		    	templateReactionReagents => [],
		    	templatecompartment_ref => "~/compartments/id/c",
		    	reverse_penalty => 5,
		    	forward_penalty => 5,
		    	base_cost => 10,
		    	GapfillDirection => "="
		 	});
		 }
	 }
	 return $rxn;
}


__PACKAGE__->meta->make_immutable;
1;
