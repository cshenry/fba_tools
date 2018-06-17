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
use POSIX;
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
	if ($self->domain() eq "Plant" || $self->taxonomy() =~ /viridiplantae/i) {
		return "plant";
	}
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
sub compute_genome_completeness {
	(my $self) = @_;
	my $universal_roles = [
		"Alanyl-tRNA synthetase (EC 6.1.1.7)",
		"Arginyl-tRNA synthetase (EC 6.1.1.19)",
		"Asparaginyl-tRNA synthetase (EC 6.1.1.22)",
		"Aspartyl-tRNA synthetase (EC 6.1.1.12)",
		"Cysteinyl-tRNA synthetase (EC 6.1.1.16)",
		"DNA-directed RNA polymerase alpha subunit (EC 2.7.7.6)",
		"DNA-directed RNA polymerase beta subunit (EC 2.7.7.6)",
		"DNA-directed RNA polymerase beta' subunit (EC 2.7.7.6)",
		"DNA-directed RNA polymerase omega subunit (EC 2.7.7.6)",
		"Glutaminyl-tRNA synthetase (EC 6.1.1.18)",
		"Glutamyl-tRNA synthetase (EC 6.1.1.17)",
		"Glycyl-tRNA synthetase alpha chain (EC 6.1.1.14)",
		"Glycyl-tRNA synthetase beta chain (EC 6.1.1.14)",
		"Histidyl-tRNA synthetase (EC 6.1.1.21)",
		"Isoleucyl-tRNA synthetase (EC 6.1.1.5)",
		"LSU ribosomal protein L10p (P0)",
		"LSU ribosomal protein L11p (L12e)",
		"LSU ribosomal protein L13p (L13Ae)",
		"LSU ribosomal protein L14p (L23e)",
		"LSU ribosomal protein L15p (L27Ae)",
		"LSU ribosomal protein L16p (L10e)",
		"LSU ribosomal protein L17p",
		"LSU ribosomal protein L18p (L5e)",
		"LSU ribosomal protein L19p",
		"LSU ribosomal protein L1p (L10Ae)",
		"LSU ribosomal protein L20p",
		"LSU ribosomal protein L21p",
		"LSU ribosomal protein L22p (L17e)",
		"LSU ribosomal protein L23p (L23Ae)",
		"LSU ribosomal protein L24p (L26e)",
		"LSU ribosomal protein L25p",
		"LSU ribosomal protein L27p",
		"LSU ribosomal protein L28p",
		"LSU ribosomal protein L29p (L35e)",
		"LSU ribosomal protein L2p (L8e)",
		"LSU ribosomal protein L30p (L7e)",
		"LSU ribosomal protein L31p",
		"LSU ribosomal protein L32p",
		"LSU ribosomal protein L33p",
		"LSU ribosomal protein L34p",
		"LSU ribosomal protein L35p",
		"LSU ribosomal protein L36p",
		"LSU ribosomal protein L3p (L3e)",
		"LSU ribosomal protein L4p (L1e)",
		"LSU ribosomal protein L5p (L11e)",
		"LSU ribosomal protein L6p (L9e)",
		"LSU ribosomal protein L7/L12 (P1/P2)",
		"LSU ribosomal protein L9p",
		"Leucyl-tRNA synthetase (EC 6.1.1.4)",
		"Lysyl-tRNA synthetase (class II) (EC 6.1.1.6)",
		"Methionyl-tRNA synthetase (EC 6.1.1.10)",
		"Phenylalanyl-tRNA synthetase alpha chain (EC 6.1.1.20)",
		"Phenylalanyl-tRNA synthetase beta chain (EC 6.1.1.20)",
		"Prolyl-tRNA synthetase (EC 6.1.1.15), bacterial type",
		"SSU ribosomal protein S10p (S20e)",
		"SSU ribosomal protein S11p (S14e)",
		"SSU ribosomal protein S12p (S23e)",
		"SSU ribosomal protein S13p (S18e)",
		"SSU ribosomal protein S14p (S29e)",
		"SSU ribosomal protein S15p (S13e)",
		"SSU ribosomal protein S16p",
		"SSU ribosomal protein S17p (S11e)",
		"SSU ribosomal protein S18p",
		"SSU ribosomal protein S19p (S15e)",
		"SSU ribosomal protein S1p",
		"SSU ribosomal protein S20p",
		"SSU ribosomal protein S21p",
		"SSU ribosomal protein S2p (SAe)",
		"SSU ribosomal protein S3p (S3e)",
		"SSU ribosomal protein S4p (S9e)",
		"SSU ribosomal protein S5p (S2e)",
		"SSU ribosomal protein S6p",
		"SSU ribosomal protein S7p (S5e)",
		"SSU ribosomal protein S8p (S15Ae)",
		"SSU ribosomal protein S9p (S16e)",
		"Seryl-tRNA synthetase (EC 6.1.1.11)",
		"Threonyl-tRNA synthetase (EC 6.1.1.3)",
		"Tryptophanyl-tRNA synthetase (EC 6.1.1.2)",
		"Tyrosyl-tRNA synthetase (EC 6.1.1.1)",
		"Valyl-tRNA synthetase (EC 6.1.1.9)",
		"ADP-dependent (S)-NAD(P)H-hydrate dehydratase (EC 4.2.1.136)",
		"tRNA-Met-CAT",
		"LSU rRNA",
		"SSU rRNA",
		"Single-stranded DNA-binding protein",
		"Large Subunit Ribosomal RNA",
		"lsuRNA",
		"tRNA-Arg",
		"PE family protein",
		"Aspartokinase (EC 2.7.2.4)",
		"Ferredoxin",
		"Small Subunit Ribosomal RNA",
		"ssuRNA",
		"tRNA-Ser",
		"Sensor histidine kinase",
		"Cell division protein FtsI [Peptidoglycan synthetase] (EC 2.4.1.129)",
		"tRNA-Leu",
		"Acyl carrier protein",
		"ClpB protein",
		"5S RNA",
		"tRNA-Asp-GTC",
		"tRNA-Gly",
		"DNA polymerase III alpha subunit (EC 2.7.7.7)",
		"tRNA-Met",
		"tRNA-Lys-TTT",
		"tRNA-Asn-GTT",
		"tRNA-Gly-GCC",
		"tRNA-Glu-TTC",
		"tRNA-Val-TAC",
		"Cell division protein FtsW",
		"tRNA-Arg-ACG",
		"tRNA-Val",
		"tRNA-Gln-TTG",
		"Ribosomal large subunit pseudouridine synthase D (EC 5.4.99.23)",
		"tRNA-Thr",
		"tRNA-Ala-TGC",
		"tRNA-Tyr-GTA",
		"tRNA-Phe-GAA",
		"tRNA-Thr-TGT",
		"SSU rRNA (adenine(1518)-N(6)/adenine(1519)-N(6))-dimethyltransferase (EC 2.1.1.182)",
		"16S rRNA (cytosine(1402)-N(4))-methyltransferase EC 2.1.1.199)",
		"Orotate phosphoribosyltransferase (EC 2.4.2.10)",
		"Chorismate synthase (EC 4.2.3.5)",
		"PTS system, cellobiose-specific IIC component (EC 2.7.1.69)",
		"tmRNA-binding protein SmpB",
		"Phosphoglycerate mutase (EC 5.4.2.11)",
		"Orotidine 5'-phosphate decarboxylase (EC 4.1.1.23)",
		"Phosphoribosylformylglycinamidine cyclo-ligase (EC 6.3.3.1)",
		"Thiamin-phosphate pyrophosphorylase (EC 2.5.1.3)",
		"Phosphoribosylamine--glycine ligase (EC 6.3.4.13)",
		"Argininosuccinate lyase (EC 4.3.2.1)",
		"GTP-binding protein TypA/BipA",
		"Pyruvate formate-lyase activating enzyme (EC 1.97.1.4)",
		"N-acetylglucosamine-1-phosphate uridyltransferase (EC 2.7.7.23)",
		"Ribosomal large subunit pseudouridine synthase B (EC 5.4.99.22)",
		"Glucose-6-phosphate 1-dehydrogenase (EC 1.1.1.49)",
		"Thymidylate kinase (EC 2.7.4.9)",
		"Holliday junction DNA helicase RuvA",
		"Metal-dependent hydrolase YbeY, involved in rRNA and/or ribosome maturation and assembly",
		"RNA polymerase sigma-70 factor, ECF subfamily",
		"ATP synthase F0 sector subunit a (EC 3.6.3.14)",
		"DNA repair protein RadA",
		"Lipoate-protein ligase A",
		"(2E,6E)-farnesyl diphosphate synthase (EC 2.5.1.10)",
		"Deoxyribose-phosphate aldolase (EC 4.1.2.4)",
		"S-adenosylmethionine:tRNA ribosyltransferase-isomerase (EC 5.-.-.-)",
		"23S rRNA (guanosine(2251)-2'-O)-methyltransferase (EC 2.1.1.185)",
		"Biopolymer transport protein ExbD/TolR",
		"Undecaprenyl diphosphate synthase (EC 2.5.1.31)",
		"Glutamate racemase (EC 5.1.1.3)",
		"GTP-binding protein Era",
		"Fructose-bisphosphate aldolase class II (EC 4.1.2.13)",
		"CCA tRNA nucleotidyltransferase (EC 2.7.7.72)",
		"Exodeoxyribonuclease VII large subunit (EC 3.1.11.6)",
		"TsaB protein, required for threonylcarbamoyladenosine (t(6)A) formation in tRNA",
		"Ribosome-binding factor A",
		"ATP synthase F0 sector subunit c (EC 3.6.3.14)",
		"Ribosome hibernation protein YhbH",
		"TsaE protein, required for threonylcarbamoyladenosine t(6)A37 formation in tRNA",
		"Preprotein translocase subunit YajC (TC 3.A.5.1.1)",
		"tRNA-Ile-GAT",
		"tRNA-Pro-TGG",
		"tRNA-Gly-TCC",
		"tRNA-Lys",
		"tRNA-His-GTG",
		"tRNA-Pro",
		"tRNA-Asn"
	];
	my $fullcount = @{$universal_roles};
	my $rolecount = 0;
	my $searchrolehash = {};
	my $ftrs = $self->features();
	for (my $i=0; $i < @{$ftrs}; $i++) {
		my $roles = $ftrs->[$i]->roles();
		for (my $j=0; $j < @{$roles}; $j++) {
			$searchrolehash->{Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($roles->[$j])}->{$ftrs->[$i]->id()} = 1;
		}
	}
	for (my $i=0; $i < @{$universal_roles}; $i++) {
		$universal_roles->[$i] = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($universal_roles->[$i]);
		if (defined($searchrolehash->{$universal_roles->[$i]})) {
			$rolecount++;
		}
	}
	return ($rolecount/$fullcount);
}

sub compute_gene_activity_threshold_using_faria_method {
	my ($self,$exp_hash) = @_;
	my $always_active_roles = [
		"Alanyl-tRNA synthetase (EC 6.1.1.7)",
		"Arginyl-tRNA synthetase (EC 6.1.1.19)",
		"Asparaginyl-tRNA synthetase (EC 6.1.1.22)",
		"Aspartyl-tRNA synthetase (EC 6.1.1.12)",
		"Cysteinyl-tRNA synthetase (EC 6.1.1.16)",
		"DNA-directed RNA polymerase alpha subunit (EC 2.7.7.6)",
		"DNA-directed RNA polymerase beta subunit (EC 2.7.7.6)",
		"DNA-directed RNA polymerase beta' subunit (EC 2.7.7.6)",
		"DNA-directed RNA polymerase omega subunit (EC 2.7.7.6)",
		"Glutaminyl-tRNA synthetase (EC 6.1.1.18)",
		"Glutamyl-tRNA synthetase (EC 6.1.1.17)",
		"Glycyl-tRNA synthetase alpha chain (EC 6.1.1.14)",
		"Glycyl-tRNA synthetase beta chain (EC 6.1.1.14)",
		"Histidyl-tRNA synthetase (EC 6.1.1.21)",
		"Isoleucyl-tRNA synthetase (EC 6.1.1.5)",
		"LSU ribosomal protein L10p (P0)",
		"LSU ribosomal protein L11p (L12e)",
		"LSU ribosomal protein L13p (L13Ae)",
		"LSU ribosomal protein L14p (L23e)",
		"LSU ribosomal protein L15p (L27Ae)",
		"LSU ribosomal protein L16p (L10e)",
		"LSU ribosomal protein L17p",
		"LSU ribosomal protein L18p (L5e)",
		"LSU ribosomal protein L19p",
		"LSU ribosomal protein L1p (L10Ae)",
		"LSU ribosomal protein L20p",
		"LSU ribosomal protein L21p",
		"LSU ribosomal protein L22p (L17e)",
		"LSU ribosomal protein L23p (L23Ae)",
		"LSU ribosomal protein L24p (L26e)",
		"LSU ribosomal protein L25p",
		"LSU ribosomal protein L27p",
		"LSU ribosomal protein L28p",
		"LSU ribosomal protein L29p (L35e)",
		"LSU ribosomal protein L2p (L8e)",
		"LSU ribosomal protein L30p (L7e)",
		"LSU ribosomal protein L31p",
		"LSU ribosomal protein L32p",
		"LSU ribosomal protein L33p",
		"LSU ribosomal protein L34p",
		"LSU ribosomal protein L35p",
		"LSU ribosomal protein L36p",
		"LSU ribosomal protein L3p (L3e)",
		"LSU ribosomal protein L4p (L1e)",
		"LSU ribosomal protein L5p (L11e)",
		"LSU ribosomal protein L6p (L9e)",
		"LSU ribosomal protein L7/L12 (L23e)",
		"LSU ribosomal protein L9p",
		"Leucyl-tRNA synthetase (EC 6.1.1.4)",
		"Lysyl-tRNA synthetase (class II) (EC 6.1.1.6)",
		"Methionyl-tRNA synthetase (EC 6.1.1.10)",
		"Phenylalanyl-tRNA synthetase alpha chain (EC 6.1.1.20)",
		"Phenylalanyl-tRNA synthetase beta chain (EC 6.1.1.20)",
		"Prolyl-tRNA synthetase (EC 6.1.1.15)",
		"SSU ribosomal protein S10p (S20e)",
		"SSU ribosomal protein S11p (S14e)",
		"SSU ribosomal protein S12p (S23e)",
		"SSU ribosomal protein S13p (S18e)",
		"SSU ribosomal protein S14p (S29e)",
		"SSU ribosomal protein S15p (S13e)",
		"SSU ribosomal protein S16p",
		"SSU ribosomal protein S17p (S11e)",
		"SSU ribosomal protein S18p",
		"SSU ribosomal protein S19p (S15e)",
		"SSU ribosomal protein S1p",
		"SSU ribosomal protein S20p",
		"SSU ribosomal protein S21p",
		"SSU ribosomal protein S2p (SAe)",
		"SSU ribosomal protein S3p (S3e)",
		"SSU ribosomal protein S4p (S9e)",
		"SSU ribosomal protein S5p (S2e)",
		"SSU ribosomal protein S6p",
		"SSU ribosomal protein S7p (S5e)",
		"SSU ribosomal protein S8p (S15Ae)",
		"SSU ribosomal protein S9p (S16e)",
		"Seryl-tRNA synthetase (EC 6.1.1.11)",
		"Threonyl-tRNA synthetase (EC 6.1.1.3)",
		"Tryptophanyl-tRNA synthetase (EC 6.1.1.2)",
		"Tyrosyl-tRNA synthetase (EC 6.1.1.1)",
		"Valyl-tRNA synthetase (EC 6.1.1.9)"
	];
	my $rolecount = 0;
	my $nonzerorolecount = 0;
	my $expvals = [];
	my $searchrolehash = {};
	my $ftrs = $self->features();
	for (my $i=0; $i < @{$ftrs}; $i++) {
		my $roles = $ftrs->[$i]->roles();
		for (my $j=0; $j < @{$roles}; $j++) {
			$searchrolehash->{Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($roles->[$j])}->{$ftrs->[$i]->id()} = 1;
		}
	}
	for (my $i=0; $i < @{$always_active_roles}; $i++) {
		$always_active_roles->[$i] = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($always_active_roles->[$i]);
		if (defined($searchrolehash->{$always_active_roles->[$i]})) {
			$rolecount++;
			my $bestexp = 0;
			foreach my $id (keys(%{$searchrolehash->{$always_active_roles->[$i]}})) {
				if (defined($exp_hash->{$id}) && $bestexp < $exp_hash->{$id}) {
					$bestexp = $exp_hash->{$id};
				}
			}
			if ($bestexp > 0) {
				$nonzerorolecount++;
				push(@{$expvals},$bestexp);
			}
		}
	}
	my $allexpvals = [];
	foreach my $gene (keys(%{$exp_hash})) {
		push(@{$allexpvals},$exp_hash->{$gene});
	}
	$allexpvals = [sort(@{$allexpvals})];
	$expvals = [sort(@{$expvals})];
	my $index = ceil($nonzerorolecount/10);
	my $cutoff = $expvals->[$index];
	my $cutoff_percentile = 0;
	my $totalexpvals = @{$allexpvals};
	for (my $i=0; $i < @{$allexpvals}; $i++) {
		if (defined $cutoff && $allexpvals->[$i] == $cutoff) {
			$cutoff_percentile = $i/$totalexpvals;
		}
	}
	$cutoff_percentile = floor(100*$cutoff_percentile)/100;
	print "Genes found for ".$rolecount." of 79 functional roles classified as always active.\n";
	print $nonzerorolecount." of these genes have nonzero expression values.\n";
	print "Cutoff value computed at an absolute expression of ".$cutoff.", which is the ".100*$cutoff_percentile." percentile.\n";
	return [$cutoff,$cutoff_percentile,$nonzerorolecount];
}


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
