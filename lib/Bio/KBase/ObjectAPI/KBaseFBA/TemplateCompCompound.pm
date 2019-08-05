########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompCompound - This is the moose object corresponding to the KBaseFBA.TemplateCompCompound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2015-10-16T03:20:25
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateCompCompound;
package Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompCompound;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::TemplateCompCompound';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has isBiomassCompound  => ( is => 'rw', isa => 'Bool',printOrder => '3', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildisBiomassCompound' );
has inchikey => (is => 'rw', type => 'Str', metaclass => 'Typed', lazy => 1, builder => '_build_inchikey');
has smiles => (is => 'rw', type => 'Str', metaclass => 'Typed', lazy => 1, builder => '_build_smiles');
has inchi => (is => 'rw', type => 'Str', metaclass => 'Typed', lazy => 1, builder => '_build_inchi');
has neutral_formula  => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildneutral_formula' );
has formula  => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildformula' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildisBiomassCompound {
	my ($self) = @_;
	$self->parent()->labelBiomassCompounds();
	return $self->isBiomassCompound();
}
sub _build_inchikey {
	my ($self) = @_;
	if ($self->id() =~ m/(cpd\d+)/) {
		my $id = $1;
		my $cpdhash = Bio::KBase::utilities::compound_hash();
		if (defined($cpdhash->{$id}->{inchikey})) {
			return $cpdhash->{$id}->{inchikey};
		}
	}
}
sub _build_inchi {
	my ($self) = @_;
	if ($self->id() =~ m/(cpd\d+)/) {
		my $id = $1;
		my $cpdhash = Bio::KBase::utilities::compound_hash();
		if (defined($cpdhash->{$id}->{search_inchi})) {
			return $cpdhash->{$id}->{search_inchi};
		}
	}
}
sub _build_smiles {
	my ($self) = @_;
	if ($self->id() =~ m/(cpd\d+)/) {
		my $id = $1;
		my $cpdhash = Bio::KBase::utilities::compound_hash();
		if (defined($cpdhash->{$id}->{smiles})) {
			return $cpdhash->{$id}->{smiles};
		}
	}
}
sub _buildneutral_formula {
	my ($self) = @_;
	my $formula = $self->templatecompound()->formula();
	my $charge = $self->charge();
	my $diff = 0-$charge;
	if ($self->id() eq "cpd00006" || $self->id() eq "cpd00003") {
		$diff++;
	}
	if ($diff == 0) {
		return $formula;
	}
	if ($formula =~ m/H(\d+)/) {
		my $count = $1;
		$count += $diff;
		$formula =~ s/H(\d+)/H$count/;
	} elsif ($formula =~ m/.H$/) {
		if ($diff < 0) {
			$formula =~ s/H$//;
		} else {
			$diff++;
			$formula .= $diff;
		}
	} elsif ($formula =~ m/H[A-Z]/) {
		if ($diff < 0) {
			$formula =~ s/H([A-Z])/$1/;
		} else {
			$diff++;
			$formula =~ s/H([A-Z])/H$diff$1/;
		}
	}
	return $formula;
}
sub _buildformula {
	my ($self) = @_;
	return $self->templatecompound()->formula();
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************


__PACKAGE__->meta->make_immutable;
1;
