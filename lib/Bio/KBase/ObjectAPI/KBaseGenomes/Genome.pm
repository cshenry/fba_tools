########################################################################
# Bio::KBase::ObjectAPI::KBaseGenomes::Genome - This is the moose object corresponding to the Genome object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseGenomes::DB::Genome;
package Bio::KBase::ObjectAPI::KBaseGenomes::Genome;
use Moose;
use Bio::KBase::ObjectAPI::utilities;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseGenomes::DB::Genome';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has geneAliasHash => ( is => 'rw',printOrder => -1, isa => 'HashRef', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildgeneAliasHash' );
has rolehash => ( is => 'rw',printOrder => -1, isa => 'HashRef', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildrolehash' );
has gene_subsystem_hash => ( is => 'rw',printOrder => -1, isa => 'HashRef', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildgene_subsystem_hash' );
has template_classification => ( is => 'rw',printOrder => -1, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildtemplate_classification' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildrolehash {
	my ($self) = @_;
	my $rolehash = {};
	my $ftrs = $self->features();
    foreach my $ftr (@{$ftrs}) {
    	my $roles = $ftr->roles();
    	for (my $i=0; $i < @{$roles}; $i++) {
    		push(@{$rolehash->{$roles->[$i]}},$ftr->id());
    	}
    }
    return $rolehash;
}
sub _buildgeneAliasHash {
	my ($self) = @_;
	my $geneAliases = {};
	my $ftrs = $self->features();
    foreach my $ftr (@{$ftrs}) {
    	$geneAliases->{$ftr->id()} = $ftr;
    	foreach my $alias (@{$ftr->aliases()}) {
    		$geneAliases->{$alias} = $ftr;
    	}
    }
    return $geneAliases;
}
sub _buildgene_subsystem_hash {
	my ($self) = @_;
	if (!defined($self->{_mapping})) {
		return {};
	}
	my $rolehash = {};
	my $sss = $self->{_mapping}->subsystems();
	foreach my $ss (@{$sss}) {
		if ($ss->class() !~ m/Experimental/ && $ss->class() !~ m/Clustering/) {
		my $roles = $ss->roles();
		foreach my $role (@{$roles}) {
			$rolehash->{$role->searchname()}->{$ss->name()} = $ss;
		}
		}
	}
	my $ftrhash = {};
	my $ftrs = $self->features();
	foreach my $ftr (@{$ftrs}) {
		my $roles = $ftr->roles();
		foreach my $role (@{$roles}) {
			my $sr = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($role);
			foreach my $ss (keys(%{$rolehash->{$sr}})) {
				$ftrhash->{$ftr->id()}->{$ss} = $rolehash->{$sr}->{$ss};
			}
		}
	}
    return $ftrhash;
}

sub _buildtemplate_classification {
	my ($self) = @_;
	my $classifier = Bio::KBase::ObjectAPI::utilities::classifier_data();
	my $scores = {};
	my $sum = 0;
	foreach my $class (keys(%{$classifier->{classifierClassifications}})) {
		$scores->{$class} = 0;
		$sum += $classifier->{classifierClassifications}->{$class}->{populationProbability};
	}
	my $features = $self->features();
	for (my $i=0; $i < @{$features}; $i++) {
		my $feature = $features->[$i];
		my $roles = $feature->roles();
		foreach my $role (@{$roles}) {
			my $searchrole = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($role);
			if (defined($classifier->{classifierRoles}->{$searchrole})) {
				foreach my $class (keys(%{$classifier->{classifierClassifications}})) {
					$scores->{$class} += $classifier->{classifierRoles}->{$searchrole}->{classificationProbabilities}->{$class};
				}
			}
		}
	}
	my $largest;
	my $largestClass;
	foreach my $class (keys(%{$classifier->{classifierClassifications}})) {
		$scores->{$class} += log($classifier->{classifierClassifications}->{$class}->{populationProbability}/$sum);
		if (!defined($largest)) {
			$largest = $scores->{$class};
			$largestClass = $class;
		} elsif ($largest > $scores->{$class}) {
			$largest = $scores->{$class};
			$largestClass = $class;
		}
	}
	return $largestClass;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub genome_typed_object {
    my ($self) = @_;
	my $output = $self->serializeToDB();
	if (defined($self->contigset_ref())) {
		my $contigset = $self->contigset();
		my $contigserial = $contigset->serializeToDB();
		$output->{contigs} = $contigserial->{contigs};
		for (my $i=0; $i < @{$output->{contigs}}; $i++) {
			$output->{contigs}->[$i]->{dna} = $output->{contigs}->[$i]->{sequence};
			delete $output->{contigs}->[$i]->{sequence};
		}
	}
	return $output;
}

=head3 searchForFeature
Definition:
	Bio::KBase::ObjectAPI::KBaseGenomes::Feature = Bio::KBase::ObjectAPI::KBaseGenomes::Feature->searchForFeature(string);
Description:
	Searches for a gene by ID, name, or alias.

=cut

sub searchForFeature {
	my ($self,$id) = @_;
	return $self->geneAliasHash()->{$id};
}

=head3 gtf_to_features

Definition:
	$self->gtf_to_features({gtffile => string,clear_features => 1});
Description:
	Builds feature array from gtf file
		
=cut
sub gtf_to_features {
	my($self,$parameters) = @_;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["gtffile"], {clear_features => 1}, $parameters );
	if ($args->{clear_features}) {
		$self->features([]);
	}
	my $array = [split(/\n/,$args->{gtffile})];
	foreach my $line (@{$array}) {
		my $row = [split(/\t/,$line)];
		my $start = $row->[3];
		my $length = abs($row->[4]-$row->[3]);
		if ($row->[6] eq "-") {
			$start += $length;
		}
		my $feature = {
			location => [[$row->[0],$start,$row->[6],$length]],
			protein_translation_length => int(abs($row->[4]-$row->[3])/3),
			dna_sequence_length => int(abs($row->[4]-$row->[3])),
			publications => [],
			subsystems => [],
			protein_families => [],
			aliases => [],
			annotations => [],
			subsystem_data => [],
			regulon_data => [],
			atomic_regulons => [],
			coexpressed_fids => [],
			co_occurring_fids => []
		};
		
		my $items = [split(/;\s*/,$row->[8])];
		foreach my $item (@{$items}){
			if ($item =~ m/(.+)\s+\"(.+)\"/) {
				my $field = $1;
				my $value = $2;
				if ($field eq "alias") {
					push(@{$feature->{aliases}},split(/,/,$value));
				} elsif ($field eq "gene_id") {
					$feature->{id} = $value;
				} elsif ($field eq "product") {
					$feature->{function} = $value;
					$feature->{annotations} = [[$value,"GTF import",time()]];
				} elsif ($field eq "orig_coding_type") {
					$feature->{type} = $value;
				} elsif ($field eq "transcript_id") {
					push(@{$feature->{aliases}},$value);
				}
			}
		}
		$self->add("features",$feature);
	}
}

=head3 integrate_contigs

Definition:
	$self->integrate_contigs({contigobj => Bio::KBase::ObjectAPI::KBaseGenomes::ContigSet,update_features => 0});
Description:
	Loads contigs into genome and updates all relevant stats
		
=cut
sub integrate_contigs {
	my($self,$parameters) = @_;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["contigobj"], {update_features => 0}, $parameters );
	my $contigobj = $args->{contigobj};
	$self->contigset_ref($contigobj->_reference());
	my $numcontigs = @{$contigobj->contigs()};
	$self->num_contigs($numcontigs);
	my $size = 0;
	my $gc_content = 0;
	my $contigs = $contigobj->contigs();
	for (my $i=0; $i < @{$contigs}; $i++) {
		$size += length($contigs->[$i]->sequence());
		$self->contig_lengths()->[$i] = length($contigs->[$i]->sequence());
		$self->contig_ids()->[$i] = $contigs->[$i]->id();
		my $copy = $contigs->[$i]->sequence();
		$copy =~ s/[gcGC]//g;
		$gc_content += ($self->contig_lengths()->[$i]-length($copy));
	}
	$self->md5($contigobj->md5());
	$self->dna_size($size);
	$self->gc_content($gc_content/$size);
	if ($args->{update_features} == 1) {
		my $ftrs = $self->features();
		for (my $i=0; $i< @{$ftrs};$i++) {
			my $ftr = $ftrs->[$i];
			$ftr->integrate_contigs($contigobj);
		}
	}
}

=head3 genome_stats

Definition:
	$self->genome_stats();
Description:
	Computing stats for the genome
		
=cut
sub genome_stats {
	my($self) = @_;
	my $genesshash = $self->gene_subsystem_hash();
	my $ftrs = $self->features();
	my $numftrs = @{$ftrs};
	my $output = {
		id => $self->id(),
		taxonomy => $self->taxonomy(),
		genome_ref => $self->_reference(),
		gc_content => $self->gc_content(),
		source => $self->source(),
		num_contigs => $self->num_contigs(),
		dna_size => $self->dna_size(),
		domain => $self->domain(),
		scientific_name => $self->scientific_name(),
		total_genes => $numftrs,
		subsystem_genes => 0,
    	subsystems => []
	};
	my $sshash = {};
	foreach my $gene (keys(%{$genesshash})) {
		if (keys(%{$genesshash->{$gene}}) > 0) {
			$output->{subsystem_genes}++;
			foreach my $ss (keys(%{$genesshash->{$gene}})) {
				if (!defined($sshash->{$ss})) {
					$sshash->{$ss} = {
						name => $ss,
						class => $genesshash->{$gene}->{$ss}->class(),
						subclass => $genesshash->{$gene}->{$ss}->subclass(),
						genes => 0
					};
					push(@{$output->{subsystems}},$sshash->{$ss});
				}
				$sshash->{$ss}->{genes}++;
			}
		}
	}
	return $output;
}

sub add_gene {
	my($self,$parameters) = @_;
	$parameters = Bio::KBase::ObjectAPI::utilities::args(["id"], {
		function => "unknown",
    	type => "peg",
    	aliases => [],
    	publications => [],
    	annotations => [],
    	protein_translation => undef,
    	dna_sequence => undef,
    	locations => []
	}, $parameters );
	$self->add("features",{
		id => $parameters->{id},
		function => $parameters->{function},
		type => $parameters->{type},
		aliases => $parameters->{aliases},
		publications => $parameters->{publications},
		annotations => $parameters->{annotations},
		protein_translation => $parameters->{protein_translation},
		dna_sequence => $parameters->{dna_sequence},
		locations => $parameters->{locations},
	})
}
__PACKAGE__->meta->make_immutable;
1;
