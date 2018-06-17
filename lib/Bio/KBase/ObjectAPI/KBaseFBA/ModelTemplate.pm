########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::ModelTemplate - This is the moose object corresponding to the ModelTemplate object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2013-04-26T05:53:23
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelTemplate;
package Bio::KBase::ObjectAPI::KBaseFBA::ModelTemplate;
use Moose;
use namespace::autoclean;
use Data::Dumper;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelTemplate';

my $cmpTranslation = {
	extracellular => "e",
    cellwall => "w",
    periplasm => "p",
    cytosol => "c",
    golgi => "g",
    endoplasm => "r",
    lysosome => "l",
    nucleus => "n",
    chloroplast => "h",
    mitochondria => "m",
    peroxisome => "x",
    vacuole => "v",
    plastid => "d",
    unknown => "u",
};

#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has biomassHash => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildbiomassHash' );
has roleSubsystemHash => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildroleSubsystemHash' );
has compoundsByAlias => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompoundsByAlias' );
has reactionsByAlias => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreactionsByAlias' );
has roleSearchNameHash => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildroleSearchNameHash' );
has biochemistry_ref => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildbiochemistry_ref' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildbiochemistry_ref {
	my ($self) = @_;
	return Bio::KBase::ObjectAPI::utilities::default_biochemistry();
}
sub _buildbiomassHash {
	my ($self) = @_;
	my $biomasshash = {};
	my $bios = $self->biomasses();
	foreach my $bio (@{$bios}) {
		my $biocpds = $bio->templateBiomassComponents();
		foreach my $cpd (@{$biocpds}) {
			$biomasshash->{$cpd->templatecompcompound()->id()} = $cpd;
		}
	}
	return $biomasshash;
}
sub _buildroleSubsystemHash {
	my ($self) = @_;
	my $hash = {};
	my $sss = $self->subsystems();
	foreach my $ss (@{$sss}) {
		my $roles = $ss->roles();
		foreach my $role (@{$roles}) {
			$hash->{$role->id()}->{$ss->id()} = $ss;
		}
	}
	return $hash;
}
sub _buildcompoundsByAlias {
	my ($self) = @_;
	my $cpdhash = {};
	my $cpds = $self->compounds();
	for (my $i=0; $i < @{$cpds}; $i++) {
		my $aliases = $cpds->[$i]->aliases();
		for (my $j=0; $j < @{$aliases}; $j++) {
			my $array = [split(/:/,$aliases->[$j])];
			if (defined($array->[1])) {
				$cpdhash->{$array->[0]}->{$array->[1]}->{$cpds->[$i]->id()} = 1;
			} else {
				$cpdhash->{name}->{$array->[0]}->{$cpds->[$i]->id()} = 1;
			}
		}
	}
	return $cpdhash;
}
sub _buildreactionsByAlias {
	my ($self) = @_;
	my $rxnhash = {};
	my $rxns = $self->reactions();
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $aliases = $rxns->[$i]->aliases();
		for (my $j=0; $j < @{$aliases}; $j++) {
			my $array = [split(/:/,$aliases->[$j])];
			if (defined($array->[1])) {
				$rxnhash->{$array->[0]}->{$array->[1]}->{$rxns->[$i]->id()} = 1;
			} else {
				$rxnhash->{name}->{$array->[0]}->{$rxns->[$i]->id()} = 1;
			}
		}
	}
	return $rxnhash;
}

sub _buildroleSearchNameHash {
	my ($self) = @_;
	my $rolehash = {};
	my $roles = $self->roles();
	for (my $i=0; $i < @{$roles}; $i++) {
		$rolehash->{$roles->[$i]->searchname()}->{$roles->[$i]->id()} = $roles->[$i];
		my $aliases = $roles->[$i]->aliases();
		for (my $j=0; $j < @{$aliases}; $j++) {
			$aliases->[$j] =~ s/^kegg://;
			$aliases->[$j] =~ s/^searchname://;
			my $search_alias = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($aliases->[$j]);
			$rolehash->{$search_alias}->{$roles->[$i]->id()} = $roles->[$i];
		}
	}
	return $rolehash;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub buildModel {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["genome","modelid"],{
		fulldb => 0,
	}, @_);
	my $genome = $args->{genome};
	my $mdl = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->new({
		id => $args->{modelid},
		source => Bio::KBase::utilities::conf("ModelSEED","source"),
		source_id => $args->{modelid},
		type => $self->type(),
		name => $genome->scientific_name(),
		genome_ref => $genome->_reference(),
		template_ref => $self->_reference(),
		template_refs => [$self->_reference()],
		gapfillings => [],
		gapgens => [],
		biomasses => [],
		modelcompartments => [],
		modelcompounds => [],
		modelreactions => []
	});
	$mdl->genome($genome);
	$mdl->_reference("~");
	$mdl->parent($self->parent());
	my $cds = [];
	my $genes = [];
	my $ftrs = $genome->features();
	for (my $i=0; $i < @{$ftrs}; $i++) {
		if (lc($ftrs->[$i]->type()) eq "cds") {
			push(@{$cds},$ftrs->[$i]);
		} elsif (lc($ftrs->[$i]->type()) ne "mrna") {
			push(@{$genes},$ftrs->[$i]);
		}
	}
	my $numcds = @{$cds};
	my $numgenes = @{$genes};
	if ($numcds >= 2*$numgenes) {
		$genes = $cds;
	}
	$self->extend_model_from_features({
		model => $mdl,
		features => $genes
	});
	my $bios = $self->biomasses();
	for (my $i=0; $i < @{$bios}; $i++) {
		my $bio = $bios->[$i];
		my $gc = $genome->gc_content();
		if (!defined($gc)) {
			$gc = 0.5;
		}
 		$bio->addBioToModel({
			gc => $gc,
			model => $mdl
		});
	}
	return $mdl;
}	
	
sub extend_model_from_features {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["features","model"],{
		fulldb => 0
	}, @_);	
	my $rxns = $self->reactions();
	my $roleFeatures = {};
	my $mdl = $args->{model};
	my $features = $args->{features};
	for (my $i=0; $i < @{$features}; $i++) {
		my $ftr = $features->[$i];
		my $roles = $ftr->roles();
		my $compartments = $ftr->compartments();
		for (my $j=0; $j < @{$roles}; $j++) {
			my $role = $roles->[$j];
			for (my $k=0; $k < @{$compartments}; $k++) {
				my $abbrev = $compartments->[$k];
				if (length($compartments->[$k]) > 1 && defined($cmpTranslation->{$compartments->[$k]})) {
					$abbrev = $cmpTranslation->{$compartments->[$k]};
				} elsif (length($compartments->[$k]) > 1 && !defined($cmpTranslation->{$compartments->[$k]})) {
					print STDERR "Compartment ".$compartments->[$k]." not found!\n";
				}
				my $searchrole = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($role);
				if (defined($self->roleSearchNameHash()->{$searchrole})) {
					foreach my $roleid (keys(%{$self->roleSearchNameHash()->{$searchrole}})) {
						if ($self->roleSearchNameHash()->{$searchrole}->{$roleid}->source() ne "KEGG") {
							push(@{$roleFeatures->{$roleid}->{$abbrev}},$ftr);
						}
					}
				}
			}
		}
	}
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $rxn = $rxns->[$i];
		$rxn->addRxnToModel({
			role_features => $roleFeatures,
			model => $mdl,
			fulldb => $args->{fulldb}
		});
	}
}

sub buildModelFromFunctions {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["functions","modelid"],{}, @_);
	my $mdl = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->new({
		id => $args->{modelid},
		source => Bio::KBase::ObjectAPI::utilities::source(),
		source_id => $args->{modelid},
		type => $self->type(),
		name => $args->{modelid},
		template_ref => $self->_reference(),
		template_refs => [$self->_reference()],
		gapfillings => [],
		gapgens => [],
		biomasses => [],
		modelcompartments => [],
		modelcompounds => [],
		modelreactions => []
	});
	my $rxns = $self->reactions();
	my $roleFeatures = {};
	foreach my $function (keys(%{$args->{functions}})) {
		my $searchrole = Bio::KBase::ObjectAPI::Utilities::GlobalFunctions::convertRoleToSearchRole($function);
		my $subroles = [split(/;/,$searchrole)];
		for (my $m=0; $m < @{$subroles}; $m++) {
			$searchrole = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($subroles->[$m]);
			if (defined($self->roleSearchNameHash()->{$searchrole})) {
				foreach my $roleid (keys(%{$self->roleSearchNameHash()->{$searchrole}})) {
					if ($self->roleSearchNameHash()->{$searchrole}->{$roleid}->source() ne "KEGG") {
						$roleFeatures->{$roleid}->{"c"}->[0] = "Role-based-annotation";
					}
				}
			}
		}
	}
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $rxn = $rxns->[$i];
		$rxn->addRxnToModel({
			role_features => $roleFeatures,
			model => $mdl
		});
	}
	my $bios = $self->biomasses();
	for (my $i=0; $i < @{$bios}; $i++) {
		my $bio = $bios->[$i];
		$bio->addBioToModel({
			gc => 0.5,
			model => $mdl
		});
	}
	return $mdl;
}

=head3 searchForBiomass

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::TemplateBiomass Bio::KBase::ObjectAPI::KBaseFBA::TemplateBiomass->searchForBiomass(string:id);
Description:
	Search for biomass in template model
	
=cut

sub searchForBiomass {
    my $self = shift;
    my $id = shift;
    my $obj = $self->queryObject("biomasses",{id => $id});
    if (!defined($obj)) {
    	$obj = $self->queryObject("biomasses",{name => $id});
    }
    return $obj;
}

=head3 searchForReaction

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::TemplateReaction Bio::KBase::ObjectAPI::KBaseFBA::TemplateBiomass->searchForReaction(string:id);
Description:
	Search for reaction in template model
	
=cut

sub searchForReaction {
    my $self = shift;
    my $id = shift;
    my $compartment = shift;
    my $index = shift;
    if ($id =~ m/^(.+)\[([a-z]+)(\d*)]$/) {
    	$id = $1;
    	$compartment = $2;
    	$index = $3;
    } elsif ($id =~ m/^(.+)_([a-z]+)(\d*)$/) {
    	$id = $1;
    	$compartment = $2;
    	$index = $3;
    }
    if (!defined($compartment)) {
    	$compartment = "c";
    }
    if (!defined($index) || length($index) == 0) {
    	$index = 0;
    }
    return $self->queryObject("reactions",{id => $id."_".$compartment});
}

=head3 searchForCompartment
Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompartment = Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompartment->searchForCompartment(string);
Description:
	Searches for a compartment by ID, name, or alias.

=cut

sub searchForCompartment {
	my ($self,$id) = @_;
	my $cmp = $self->queryObject("compartments",{id => $id});
	#First search by exact alias match
	if (!defined($cmp)) {
		$cmp = $self->getObjectByAlias("compartments",$id);
	}
	#Next, search by name
	if (!defined($cmp)) {
		$cmp = $self->queryObject("compartments",{name => $id});
	}
	return $cmp;
}

=head3 searchForRoles
Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::TemplateRole = Bio::KBase::ObjectAPI::KBaseFBA::TemplateRole->searchForRoles(string);
Description:
	Searches for a role by ID, name, or alias.

=cut

sub searchForRoles {
	my ($self,$id) = @_;
	#First search by exact alias match
	my $roleobjs = $self->getObjectsByAlias("roles",$id);
	#Next, search by name
	if (!defined($roleobjs->[0])) {
		$roleobjs = $self->queryObjects("roles",{name => $id});
	}
	if (!defined($roleobjs->[0])) {
		$roleobjs = $self->queryObjects("roles",{searchname => $id});
	}
	return $roleobjs;
}

=head3 searchForCompound
Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompound = Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompound->searchForCompound(string);
Description:
	Searches for a compound by ID, name, or alias.

=cut

sub searchForCompound {
	my ($self,$compound,$searchbio) = @_;
	#First search by exact alias match
	my $cpdobj = $self->getObject("compounds",$compound);
	#Next, search by name
	if (!defined($cpdobj)) {
		my $searchname = Bio::KBase::ObjectAPI::KBaseFBA::TemplateCompound->nameToSearchname($compound);
		$cpdobj = $self->queryObject("compounds",{searchnames => $searchname});
	}
	if (!defined($cpdobj) && defined($searchbio)) {
		$cpdobj = $self->biochemistry()->searchForCompound($compound);
		if (defined($cpdobj)) {
			$cpdobj = $self->getObject("compounds",$cpdobj->id());
		}
	}
	return $cpdobj;
}

sub checkForProton {
    my ($self) = @_;
    my $obj=$self->getObject("compounds","cpd00067");
    return $obj if $obj;
    $obj=$self->getObjectByAlias("compounds","cpd00067","ModelSEED");
    return $obj if $obj;
    $obj=$self->getObjectByAlias("compounds","C00080","KEGG");
    return $obj if $obj;
    $obj=$self->getObjectByAlias("compounds","PROTON","MetaCyc");
    return $obj if $obj;
    return $self->queryObject("compounds",{name => "H+"});
}

sub checkForWater {
    my ($self) = @_;
    my $obj=$self->getObject("compounds","cpd00001");
    return $obj if $obj;
    $obj=$self->getObjectByAlias("compounds","cpd00001","ModelSEED");
    return $obj if $obj;
    $obj=$self->getObjectByAlias("compounds","C00001","KEGG");
    return $obj if $obj;
    $obj=$self->getObjectByAlias("compounds","WATER","MetaCyc");
    return $obj if $obj;
    return $self->queryObject("compounds",{name => "Water"});
}

=head3 labelBiomassCompounds

Definition:
	void Bio::KBase::ObjectAPI::KBaseFBA::ModelTemplate->labelBiomassCompounds();
Description:
	Labels all model compounds indicating whether or not they are biomass components

=cut

sub labelBiomassCompounds {
	my $self = shift;
	for (my $i=0; $i < @{$self->compounds()}; $i++) {
		my $cpd = $self->compounds()->[$i];
		$cpd->isBiomassCompound(0);
	}
	for (my $i=0; $i < @{$self->biomasses()}; $i++) {
		my $bio = $self->biomasses()->[$i];
		for (my $j=0; $j < @{$bio->templateBiomassComponents()}; $j++) {
			my $biocpd = $bio->templateBiomassComponents()->[$j];
			$biocpd->templatecompcompound()->isBiomassCompound(1);
		}
	}
}

=head3 searchForReactionByCode
Definition:
	{rxnobj => ,dir => } = Bio::KBase::ObjectAPI::KBaseFBA::ModelTemplate::searchForReactionByCode(string);
Description:
	Searches for a reaction by its code

=cut

sub searchForReactionByCode {
	my ($self,$code) = @_;
	my $output = {dir => "f"};
	$output->{rxnobj} = $self->queryObject("reactions",{equationCode => $code});
	if (!defined($output->{rxnobj})) {
		$output->{rxnobj} = $self->queryObject("reactions",{revEquationCode => $code});
		$output->{dir} = "r";
	}
	if (!defined($output->{rxnobj})) {
		return undef;
	}
	return $output;
}

sub getObjectByAlias {
	my ($self,$attribute,$alias,$aliasName) = @_;
	my $objs = $self->getObjectsByAlias($attribute,$alias,$aliasName);
	if (defined($objs->[0])) {
        return $objs->[0];
    } else {
        return;
    }
}

sub getObjectsByAlias {
	my ($self,$attribute,$alias,$aliasName) = @_;
	my $objects = [];
	if (defined($alias)) {
		my $aliasHash;
		if ($attribute eq "compounds") {
			$aliasHash = $self->compoundsByAlias();
		} elsif ($attribute eq "reactions") {
			$aliasHash = $self->reactionsByAlias();
		}
		if (!defined($aliasName)) {
			my $uuidhash = {};
			foreach my $set (keys(%{$aliasHash})) {
				if (defined($aliasHash->{$set}->{$alias})) {
					foreach my $uuid (keys(%{$aliasHash->{$set}->{$alias}})) {
						$uuidhash->{$uuid} = 1;
					}
				}
			}
			$objects = $self->getObjects($attribute,[keys(%{$uuidhash})]);
		} else {
			my $uuidhash = {};
			if (defined($aliasHash->{$aliasName})) {
				foreach my $uuid (keys(%{$aliasHash->{$aliasName}->{$alias}})) {
					$uuidhash->{$uuid} = 1;
				}
				$objects = $self->getObjects($attribute,[keys(%{$uuidhash})]);
			}
		}
	}
	return $objects;
}

sub printTSV {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args([], {file => 0,path => undef,append_to => {
		compounds_table => ["id\tname\tformula\tcharge\tinchikey\tsmiles\tdeltag\tkegg id\tms id\tin model"],
		reactions_table => ["id\tdirection\tcompartment\tgpr\tname\tenzyme\tdeltag\treference\tequation\tdefinition\tms id\tbigg id\tkegg id\tkegg pathways\tmetacyc pathways\tin model"]
	},compound_filter => {},reaction_filter => {}}, @_);
	my $output = $args->{append_to};
	my $kegghash = Bio::KBase::utilities::kegg_hash();
	my $cpdhash = Bio::KBase::utilities::compound_hash();
	my $rxnhash = Bio::KBase::utilities::reaction_hash();
	my $compounds = $self->compcompounds();
	my $cpd_id_hash = {};
	my $rxn_id_hash = {};
	for (my $i=0; $i < @{$compounds}; $i++) {
		my $cpddata;
		my $msid = "";
		if (!defined($args->{compound_filter}->{$compounds->[$i]->id()."0"})) {
			if ($compounds->[$i]->id() =~ m/(cpd\d+)/ || $compounds->[$i]->compound_ref() =~ m/(cpd\d+)/) {
				$msid = $1;
				if ($msid ne "" && $msid ne "cpd00000" && defined($cpdhash->{$msid})) {
					$cpddata = $cpdhash->{$msid};
				}
			}
			my $name = $compounds->[$i]->id();
			if (defined($cpddata)) {
				$name = $cpddata->{name};
			}
			my $formula = "";
			if (defined($compounds->[$i]->formula()) && length($compounds->[$i]->formula()) > 0) {
				$formula = $compounds->[$i]->formula();
			} elsif (defined($cpddata) && defined($cpddata->{formula})) {
				$formula = $cpddata->{formula};
			}
			my $charge = "";
			if (defined($compounds->[$i]->charge()) && length($compounds->[$i]->charge()) > 0) {
				$charge = $compounds->[$i]->charge();
			} elsif (defined($cpddata)) {
				$charge = $cpddata->{charge};
			}
			my $inchikey = "";
			if (defined($cpddata) && defined($cpddata->{inchikey})) {
				$inchikey = $cpddata->{inchikey};
			}
			my $smiles = "";
			if (defined($cpddata) && defined($cpddata->{smiles})) {
				$smiles = $cpddata->{smiles};
			}
			my $deltag = "";
			if (defined($cpddata) && defined($cpddata->{deltag}) && $cpddata->{deltag} != 10000000) {
				$deltag = $cpddata->{deltag};
			}
			my $keggid = "";
			if (defined($cpddata) && defined($cpddata->{kegg_aliases}->[0])) {
				$keggid = $cpddata->{kegg_aliases}->[0];
			}
			my $line = $compounds->[$i]->id()."0\t".$name."\t".$formula."\t".$charge."\t".$inchikey."\t".$smiles."\t".$deltag."\t".$keggid."\t".$msid."\t0";
			push(@{$output->{compounds_table}},$line);
		}
	}
	my $reactions = $self->reactions();
	for (my $i=0; $i < @{$reactions}; $i++) {
		if (!defined($args->{reaction_filter}->{$reactions->[$i]->id()."0"})) {
			my $pathway = "";
			my $reference = "";
			my $equation = $reactions->[$i]->equation();
			$equation =~ s/\)/) /g;
			my $definition = $reactions->[$i]->definition();
			$definition =~ s/\)/) /g;
			my $rxndata;
			my $msid = "";
			$rxn_id_hash->{$reactions->[$i]->id()} = 1;
			if ($reactions->[$i]->id() =~ m/(rxn\d+)/ || $reactions->[$i]->reaction_ref() =~ m/(rxn\d+)/) {
				$msid = $1;
				if ($msid ne "" && $msid ne "rxn00000" && defined($rxnhash->{$msid})) {
					$rxndata = $rxnhash->{$msid};
				}
			}
			my $deltag = "";
			if (defined($rxndata) && defined($rxndata->{deltag}) && $rxndata->{deltag} != 10000000) {
				$deltag = $rxndata->{deltag};
			}
			my $ec = "";
			if (defined($rxndata) && defined($rxndata->{ec_numbers}) && defined($rxndata->{ec_numbers}->[0])) {
				$ec = join("|", @{$rxndata->{ec_numbers}});
			}
			my $biggid = "";
			if (defined($rxndata) && defined($rxndata->{bigg_aliases}) && defined($rxndata->{bigg_aliases}->[0])) {
				$biggid = $rxndata->{bigg_aliases}->[0];
			}
			my $keggid = "";
			if (defined($rxndata) && defined($rxndata->{kegg_aliases}) && defined($rxndata->{kegg_aliases}->[0])) {
				$keggid = $rxndata->{kegg_aliases}->[0];
			}
	
			my $metapath = "";
			if (defined($rxndata) && defined($rxndata->{metacyc_pathways}) && defined($rxndata->{metacyc_pathways}->[0])) {
				for (my $j=0; $j < @{$rxndata->{metacyc_pathways}}; $j++) {
					if ($rxndata->{metacyc_pathways}->[$j] !~ /PWY-\d+/) {
						if (length($metapath) > 0) {
							$metapath .= "|";
						}
						$metapath .= $rxndata->{metacyc_pathways}->[$j];
					}
				}
			}
			my $keggpath = "";
			if (defined($rxndata) && defined($rxndata->{kegg_pathways}) && defined($rxndata->{kegg_pathways}->[0])) {
				for (my $j=0; $j < @{$rxndata->{kegg_pathways}}; $j++) {
					if (defined($kegghash->{$rxndata->{kegg_pathways}->[$j]})) {
						if (length($keggpath) > 0) {
							$keggpath .= "|";
						}
						$keggpath .= $kegghash->{$rxndata->{kegg_pathways}->[$j]};
					}
				}
			}
			my $line = $reactions->[$i]->id()."0\t".$reactions->[$i]->direction()."\t".$reactions->[$i]->templatecompartment()->id()."\t\t".$reactions->[$i]->name()."\t".$ec."\t".$deltag."\t".$reference."\t".$equation."\t".$definition."\t".$msid."\t".$biggid."\t".$keggid."\t".$keggpath."\t".$metapath."\t0";
			push(@{$output->{reactions_table}},$line);
		}
	}
	if ($args->{file} == 1) {
		Bio::KBase::ObjectAPI::utilities::PRINTFILE($args->{path}."/".$self->id()."-compounds.tsv",$output->{compounds_table});
		Bio::KBase::ObjectAPI::utilities::PRINTFILE($args->{path}."/".$self->id()."-reactions.tsv",$output->{reactions_table});
		return [$args->{path}."/".$self->id()."-compounds.tsv",$args->{path}."/".$self->id()."-reactions.tsv"];
	}
	return $output;
}

__PACKAGE__->meta->make_immutable;
1;
