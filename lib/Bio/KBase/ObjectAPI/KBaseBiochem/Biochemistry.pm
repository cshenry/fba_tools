########################################################################
# Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry - This is the moose object corresponding to the Biochemistry object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseBiochem::DB::Biochemistry;
use Bio::KBase::ObjectAPI::KBaseBiochem::BiochemistryStructures;
package Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry;
use Moose;
use Bio::KBase::ObjectAPI::utilities;

use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseBiochem::DB::Biochemistry';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has definition => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_builddefinition' );
has dataDirectory => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_builddataDirectory' );
has reactionRoleHash => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreactionRoleHash' );
has compoundsByAlias => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompoundsByAlias' );
has reactionsByAlias => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreactionsByAlias' );
has compound_reaction_hash => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompound_reaction_hash' );
has neighboring_reaction_hash => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildneighboring_reaction_hash' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildneighboring_reaction_hash {
	my ($self) = @_;
	my $hash = {};
	my $cpdhash = {};
	my $rxns = $self->reactions();
	foreach my $rxn (@{$rxns}) {
		my $rgts = $rxn->reagents();
		foreach my $rgt (@{$rgts}) {
			if (Bio::KBase::ObjectAPI::utilities::IsCofactor($rgt->compound()->id()) == 0) {
				$cpdhash->{$rgt->compound()->id()."_".$rgt->compartment()->id()}->{$rxn->id()} = $rgt->coefficient();
			}
		}
	}
	foreach my $key (keys(%{$cpdhash})) {
		if ($key =~ m/_c$/) {
			my $rxnlist = [keys(%{$cpdhash->{$key}})];
			for (my $i=0; $i < @{$rxnlist}; $i++) {
				for (my $j=0; $j < @{$rxnlist}; $j++) {
					if ($i != $j) {
						$hash->{$rxnlist->[$i]}->{$rxnlist->[$j]}->{$key} = 1;
					}
				}
			}
		}
	}
	return $hash;
}

sub _buildcompound_reaction_hash {
	my ($self) = @_;
	my $hash = {};
	my $rxns = $self->reactions();
	foreach my $rxn (@{$rxns}) {
		my $rgts = $rxn->reagents();
		foreach my $rgt (@{$rgts}) {
			$hash->{$rgt->compound()->id()}->{$rgt->compartment()->id()}->{$rxn->id()} = $rgt->coefficient();
		}
	}
	return $hash;
}

sub _builddefinition {
	my ($self) = @_;
	return $self->createEquation({format=>"name",hashed=>0});
}
sub _builddataDirectory {
	my ($self) = @_;
	my $config = ModelSEED::Configuration->new();
	if (defined($config->user_options()->{MFATK_CACHE})) {
		return $config->user_options()->{MFATK_CACHE}."/";
	}
	return Bio::KBase::ObjectAPI::utilities::MODELSEEDCORE()."/data/";
}
sub _buildcompoundsByAlias {
	my ($self) = @_;
	my $cpdhash = {};
	my $cpdaliases = $self->compound_aliases();
	foreach my $cpdid (keys(%{$cpdaliases})) {
		foreach my $aliastype (keys(%{$cpdaliases->{$cpdid}})) {
			for my $alias (@{$cpdaliases->{$cpdid}->{$aliastype}}) {
				$cpdhash->{$aliastype}->{$alias}->{$cpdid} = 1; 
			}
		}
	}
	return $cpdhash;
}
sub _buildreactionsByAlias {
	my ($self) = @_;
	my $cpdhash = {};
	my $cpdaliases = $self->reaction_aliases();
	foreach my $cpdid (keys(%{$cpdaliases})) {
		foreach my $aliastype (keys(%{$cpdaliases->{$cpdid}})) {
			for my $alias (@{$cpdaliases->{$cpdid}->{$aliastype}}) {
				$cpdhash->{$aliastype}->{$alias}->{$cpdid} = 1; 
			}
		}
	}
	return $cpdhash;
}
sub _buildreactionRoleHash {
	my ($self) = @_;
	my $hash;
	my $complexes = $self->mapping()->complexes();
	for (my $i=0; $i < @{$complexes}; $i++) {
		my $complex = $complexes->[$i];
		my $cpxroles = $complex->complexroles();
		my $cpxrxns = $complex->reaction_uuids();
		for (my $j=0; $j < @{$cpxroles}; $j++) {
			my $role = $cpxroles->[$j]->role();
			for (my $k=0; $k < @{$cpxrxns}; $k++) {
				$hash->{$cpxrxns->[$k]}->{$role->uuid()} = $role;
			}
		}
	}
	return $hash;
}

sub addAlias {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["attribute","aliasName","alias","uuid"], {}, @_);
	my $idhash;
	my $aliasHash;
	if ($args->{attribute} eq "compounds") {
		$idhash = $self->compound_aliases();
		$aliasHash = $self->compoundsByAlias();
	} elsif ($args->{attribute} eq "reactions") {
		$idhash = $self->reaction_aliases();
		$aliasHash = $self->reactionsByAlias();
	}
	if (!defined($aliasHash->{$args->{aliasName}}->{$args->{alias}}->{$args->{uuid}})) {
		$aliasHash->{$args->{aliasName}}->{$args->{alias}}->{$args->{uuid}} = 1;
		push(@{$idhash->{$args->{uuid}}->{$args->{aliasName}}},$args->{alias});
	}
}

sub removeAlias {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::Util::utilities::args(["attribute","aliasName","alias","uuid"], {}, @_);
	my $idhash;
	my $aliasHash;
	if ($args->{attribute} eq "compounds") {
		$idhash = $self->compound_aliases();
		$aliasHash = $self->compoundsByAlias();
	} elsif ($args->{attribute} eq "reactions") {
		$idhash = $self->reaction_aliases();
		$aliasHash = $self->reactionsByAlias();
	}
	if (defined($idhash->{$args->{uuid}})) {
		if (defined($idhash->{$args->{uuid}}->{$args->{aliasName}})) {
			for (my $i=0; $i < @{$idhash->{$args->{uuid}}->{$args->{aliasName}}}; $i++) {
				if ($idhash->{$args->{uuid}}->{$args->{aliasName}}->[$i] eq $args->{alias}) {
					splice(@{$idhash->{$args->{uuid}}->{$args->{aliasName}}}, $i, 1);
					$i--;
					delete $aliasHash->{$args->{aliasName}}->{$args->{alias}}->{$args->{uuid}};
				}
			}
		}
	}
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

=head3 printDBFiles

	$biochemistry->printDBFiles(
		forceprint => boolean,
        directory  => string,
	);

Creates files with biochemistry data for use by the MFAToolkit.
C<forceprint> is a boolean which, if true, will cause the function
to always print the files, overwriting existing files if they exist.
C<directory> is the directory to save the tables into.

=cut

sub printDBFiles {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args([],{
        forceprint => 0,
        directory  => $self->dataDirectory."/fbafiles/",
    }, @_);
    my $path = $args->{directory};
    File::Path::mkpath($path) unless(-d $path);
    my $print_table = sub {
        my ($filename, $header, $attributes, $objects) = @_;
        open(my $fh, ">", $filename) || die "Could not open $filename: $!";
        print $fh join("\t", @$header) . "\n";
        foreach my $object (@$objects) {
            my @line;
            foreach my $attr (@$attributes) {
                my $value = $object->$attr();
                $value = "" unless defined $value;
                push(@line, $value);
            }
            print $fh join("\t", @line) . "\n";
        }
        close $fh;
    };
    my $name = $self->uuid();
    $name =~ s/\//_/g;
    my $compound_filename = $path.$name."-compounds.tbl";
    if (!-e $compound_filename || $args->{forceprint}) {
        my $header      = [ qw(abbrev charge deltaG deltaGErr formula id mass name) ];
        my $attributes  = [ qw(abbreviation defaultCharge deltaG deltaGErr formula id mass name) ];
        my $compounds   = $self->compounds;
        $print_table->($compound_filename, $header, $attributes, $compounds);
    }
    my $reaction_filename = $path.$name."-reactions.tbl";
    if (!-e $reaction_filename || $args->{forceprint}) {
        my $header      = [ qw(abbrev deltaG deltaGErr equation id name reversibility status thermoReversibility) ];
        my $attributes  = [ qw(abbreviation deltaG deltaGErr equation id name direction status thermoReversibility) ];
        my $reactions   = $self->reactions;
        $print_table->($reaction_filename, $header, $attributes, $reactions);
    }
}

=head3 export

Definition:
	string = Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry->export({
		format => optfluxmedia/readable/html/json
	});
Description:
	Exports biochemistry data to the specified format.

=cut

sub export {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["format"], {}, @_);
	if (lc($args->{format}) eq "readable") {
		return $self->toReadableString();
	} elsif (lc($args->{format}) eq "html") {
		return $self->createHTML();
	} elsif (lc($args->{format}) eq "json") {
		return $self->toJSON({pp => 1});
	}
	Bio::KBase::ObjectAPI::utilities::error("Unrecognized type for export: ".$args->{format});
}

=head3 findCreateEquivalentCompartment
Definition:
	void Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry->findCreateEquivalentCompartment({
		compartment => Bio::KBase::ObjectAPI::KBaseBiochem::Compartment(REQ),
		create => 0/1(1)
	});
Description:
	Search for an equivalent comparment for the input biochemistry compartment

=cut

sub findCreateEquivalentCompartment {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["compartment"], {create => 1}, @_);
	my $incomp = $args->{compartment};
	my $outcomp = $self->queryObject("compartments",{
		name => $incomp->name()
	});
	if (!defined($outcomp) && $args->{create} == 1) {
		$outcomp = $self->biochemistry()->add("compartments",{
			id => $incomp->id(),
			name => $incomp->name(),
			hierarchy => $incomp->hierarchy()
		});
	}
	$incomp->mapped_uuid($outcomp->uuid());
	$outcomp->mapped_uuid($incomp->uuid());
	return $outcomp;
}

=head3 findCreateEquivalentCompound
Definition:
	void Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry->findCreateEquivalentCompound({
		compound => Bio::KBase::ObjectAPI::KBaseBiochem::Compound(REQ),
		create => 0/1(1)
	});
Description:
	Search for an equivalent compound for the input biochemistry compound

=cut

sub findCreateEquivalentCompound {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["compound"], {create => 1}, @_);
	my $incpd = $args->{compound};
	my $outcpd = $self->queryObject("compounds",{
		name => $incpd->name()
	});
	if (!defined($outcpd) && $args->{create} == 1) {
		$outcpd = $self->biochemistry()->add("compounds",{
			name => $incpd->name(),
			abbreviation => $incpd->abbreviation(),
			unchargedFormula => $incpd->unchargedFormula(),
			formula => $incpd->formula(),
			mass => $incpd->mass(),
			defaultCharge => $incpd->defaultCharge(),
			deltaG => $incpd->deltaG(),
			deltaGErr => $incpd->deltaGErr(),
		});
		for (my $i=0; $i < @{$incpd->structures()}; $i++) {
			my $cpdstruct = $incpd->structures()->[$i];
			$outcpd->add("structures",$cpdstruct->serializeToDB());
		}
		for (my $i=0; $i < @{$incpd->pks()}; $i++) {
			my $cpdpk = $incpd->pks()->[$i];
			$outcpd->add("pks",$cpdpk->serializeToDB());
		}
	}
	$incpd->mapped_uuid($outcpd->uuid());
	$outcpd->mapped_uuid($incpd->uuid());
	return $outcpd;
}

=head3 findCreateEquivalentReaction
Definition:
	void Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry->findCreateEquivalentReaction({
		reaction => Bio::KBase::ObjectAPI::KBaseBiochem::Reaction(REQ),
		create => 0/1(1)
	});
Description:
	Search for an equivalent reaction for the input biochemistry reaction

=cut

sub findCreateEquivalentReaction {
    my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["reaction"], {create => 1}, @_);
	my $inrxn = $args->{reaction};
	my $outrxn = $self->queryObject("reactions",{
		definition => $inrxn->definition()
	});
	if (!defined($outrxn) && $args->{create} == 1) { 
		$outrxn = $self->biochemistry()->add("reactions",{
			name => $inrxn->name(),
			abbreviation => $inrxn->abbreviation(),
			direction => $inrxn->direction(),
			thermoReversibility => $inrxn->thermoReversibility(),
			defaultProtons => $inrxn->defaultProtons(),
			status => $inrxn->status(),
			deltaG => $inrxn->deltaG(),
			deltaGErr => $inrxn->deltaGErr(),
		});
		my $rgts = $inrxn->reagents(); 
		for (my $i=0; $i < @{$rgts}; $i++) {
			my $rgt = $rgts->[$i];
			my $cpd = $self->biochemistry()->findCreateEquivalentCompound({
				compound => $rgt->compound(),
				create => 1
			});
			my $cmp = $self->findCreateEquivalentCompartment({
				compartment => $rgt->compartment(),
				create => 1
			});
			$outrxn->add("reagents",{
				compound_uuid => $cpd->uuid(),
				compartment_uuid => $cmp->uuid(),
				coefficient => $rgt->coefficient(),
				isCofactor => $rgt->isCofactor(),
			});
		}
	}	
	$inrxn->mapped_uuid($outrxn->uuid());
	$outrxn->mapped_uuid($inrxn->uuid());
	return $outrxn;
}

=head3 validate
Definition:
	void Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry->validate();
Description:
	This command runs a series of tests on the biochemistry data to ensure that it is valid

=cut

sub validate {
	my ($self) = @_;
	my $errors = [];
	#Check uniqueness of compound names and abbreviations
	my $cpds = $self->compounds();
	my $nameHash;
	my $abbrevHash;
	foreach my $cpd (@{$cpds}) {
		if (defined($nameHash->{$cpd->name()})) {
			push(@{$errors},"Compound names match: ".$cpd->name().": ".$cpd->uuid()."(".$cpd->id().")\t".$nameHash->{$cpd->name()}->uuid()."(".$nameHash->{$cpd->name()}->id().")");
		} else {
			$nameHash->{$cpd->name()} = $cpd;
		}
		if (defined($abbrevHash->{$cpd->abbreviation()})) {
			push(@{$errors},"Compound abbreviations match: ".$cpd->abbreviation().": ".$cpd->uuid()."(".$cpd->id().")\t".$abbrevHash->{$cpd->abbreviation()}->uuid()."(".$abbrevHash->{$cpd->abbreviation()}->id().")");
		} else {
			$abbrevHash->{$cpd->abbreviation()} = $cpd;
		}
	}
	return $errors;
}

=head3 findReactionsWithReagent
Definition:
	void Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry->findReactionsWithReagent();
Description:
	This command returns an arrayref of reactions that contain a specificed reagent uuid

=cut

sub findReactionsWithReagent {
    my ($self, $cpd) = @_;
    my $reactions = $self->reactions();
    my $found_reactions = [];
    foreach my $rxn (@$reactions){
	push(@$found_reactions, $rxn) if $rxn->hasReagent($cpd);
    }
    return $found_reactions;
}

=head3 addCompartmentFromHash
Definition:
	Bio::KBase::ObjectAPI::KBaseBiochem::Compartment = Bio::KBase::ObjectAPI::KBaseBiochem::Compartment->addCompartmentFromHash({[]});
Description:
	This command adds a single compartment from an input hash
=cut

sub addCompartmentFromHash {
    my ($self,$arguments) = @_;
    $arguments = Bio::KBase::ObjectAPI::utilities::args(["name","id"],{ hierarchy=>3 }, $arguments);

    #check to see if compartment doesn't already exist
    my $cpt = $self->queryObject("compartments",{name => $arguments->{name}});
    if (defined($cpt)) {
	Bio::KBase::ObjectAPI::utilities::verbose("Compartment found with matching name ".$arguments->{name});
	return $cpt;
    }

    Bio::KBase::ObjectAPI::utilities::verbose("Creating compartment ".$arguments->{name}." with id: ".$arguments->{id});
    $cpt = $self->add("compartments",{
	id => $arguments->{id},
	name => $arguments->{name},
	hierarchy => $arguments->{hierarchy}});
    if($arguments->{uuid}){
	$cpt->uuid($arguments->{uuid});
    }
}

=head3 addCueFromHash
Definition:
	Bio::KBase::ObjectAPI::KBaseBiochem::Cue = Bio::KBase::ObjectAPI::KBaseBiochem::Cue->addCueFromHash({[]});
Description:
	This command adds a single structural cue from an input hash
=cut

sub addCueFromHash {
    my ($self,$arguments) = @_;
    $arguments = Bio::KBase::ObjectAPI::utilities::args(["name"],{ energy=>[10000000], error=>[10000000], charge=>[10000000] }, $arguments);

    #check to see if cue doesn't already exist
    my $cue = $self->queryObject("cues",{name => $arguments->{name}});
    if (defined($cue)) {
	Bio::KBase::ObjectAPI::utilities::verbose("Cue found with matching name ".$arguments->{name});
	return $cue;
    }

    Bio::KBase::ObjectAPI::utilities::verbose("Creating cue ".$arguments->{name});
    $cue = $self->add("cues",{
	name => $arguments->{name}->[0],
	smallMolecule => $arguments->{smallMolecule}->[0],
	deltaG => $arguments->{energy}->[0],
	defaultCharge => $arguments->{charge}->[0],
	deltaGErr => $arguments->{error}->[0],
	formula => $arguments->{formula}->[0]});

    if($arguments->{uuid}){
	$cue->uuid($arguments->{uuid}->[0]);
    }
}

=head3 add_compound
Definition:
	Bio::KBase::ObjectAPI::KBaseBiochem::Compound = Bio::KBase::ObjectAPI::KBaseBiochem::Compound->add_compound({
		name => string,
		abbreviation => string,
		aliases => [string],
		formula => string,
		charge => float,
		isCofactor => bool,
		structureString => string,
		structureType => string,
	});
Description:
	This command adds a single compound from an input hash

=cut
sub add_compound {
	my ($self,$args) = @_;
    $args = Bio::KBase::ObjectAPI::utilities::args(["name"],{
		id => undef,
		abbreviation => $args->{name},
		aliases => [],
		formula => "unknown",
		charge => 0,
		isCofactor => 0,
		structureString => undef,
		structureType => undef
    },$args);
	my $cpd = $self->searchForCompound($args->{name});
	if (defined($cpd)) {
		Bio::KBase::ObjectAPI::utilities::error("Compound found with same name:".$args->{name}."!");
	}
	$cpd = $self->searchForCompound($args->{abbreviation});
	if (defined($cpd)) {
		Bio::KBase::ObjectAPI::utilities::error("Compound found with same abbreviation:".$args->{abbreviation}."!");
	}
	foreach my $alias (@{$args->{aliases}}) {
		if (length($alias) > 0 && $alias =~ m/[a-zA-Z]/) {
			if ($alias =~ m/(.+):([^:]+)/) {
				$alias = $2;
				$cpd = $self->searchForCompound($alias);
			} else {
				$cpd = $self->searchForCompound($alias);
			}
			if (defined($cpd)) {
				Bio::KBase::ObjectAPI::utilities::error("Compound found with same alias:".$alias."!");
			}
		}
	}
	if (!defined($args->{id})) {
		$args->{id} = "cpd31000";
		while (defined($self->getObject("compounds",$args->{id}))) {
			$args->{id}++;
		}
	} elsif (defined($self->getObject("compounds",$args->{id}))) {
		Bio::KBase::ObjectAPI::utilities::error("Compound found with specified ID already exists:".$args->{id}."!");
	}
	my $cpdobj = $self->add("compounds",{
		id => $args->{id},
		name => $args->{name},
		abbreviation => $args->{abbreviation},
		formula => $args->{formula},
		unchargedFormula => $args->{formula},
		mass => 0,
		defaultCharge => $args->{charge},
		deltaG => 0,
		deltaGErr => 0
	});
	foreach my $alias (@{$args->{aliases}}) {
		if ($alias =~ m/(.+):([^:]+)/) {
			$self->addAlias({
				attribute => "compounds",
				aliasName => $1,
				alias => $2,
				uuid => $args->{id}
			});
		} else {
			$self->addAlias({
				attribute => "compounds",
				aliasName => "name",
				alias => $alias,
				uuid => $args->{id}
			});
		}
	}
	return $cpdobj;
}
=head3 addCompoundFromHash
Definition:
	Bio::KBase::ObjectAPI::KBaseBiochem::Compound = Bio::KBase::ObjectAPI::KBaseBiochem::Compound->addCompoundFromHash({[]});
Description:
	This command adds a single compound from an input hash

=cut

sub addCompoundFromHash {
    my ($self,$arguments) = @_;
    $arguments = Bio::KBase::ObjectAPI::utilities::args(["names","id"],{
	reference => "",
	namespace => "ModelSEED",
	matchbyname => 0,
	mergeto => [],
	abbreviation => undef,
	formula => "unknown",
	unchargedFormula => "unknown", # where is this used?
	mass => 10000000,
	charge => 10000000,
	deltag => 10000000,
	deltagerr => 10000000,
	pkas => {},
	pkbs => {},
	addmergealias => 0}, $arguments);

    #delete reference argument if not used, to be sure of no collusion
    delete($arguments->{reference});

    # Remove names that are too long
    # $arguments->{names} = [ grep { length($_) < 255 } @{$arguments->{names}} ];
    $arguments->{names} = [$arguments->{id}] unless defined $arguments->{names}[0];
    $arguments->{abbreviation} = [$arguments->{names}[0]] unless defined $arguments->{abbreviation};

    # Checking for id uniqueness within scope of own aliasType

    #Check to see if id already exists
    my $cpd = $self->getObject("compounds",$arguments->{id});
    $cpd = $self->getObjectByAlias("compounds",$arguments->{id},$arguments->{namespace}) if !defined($cpd);
    if (defined($cpd)) {
	Bio::KBase::ObjectAPI::utilities::verbose("Compound found (".$cpd->id().") with matching id ".$arguments->{id}." for namespace ".$arguments->{namespace});
	if($arguments->{addmergealias}){
	    foreach my $aliasType (@{$arguments->{mergeto}}){
		$self->addAlias({ attribute => "compounds",
				  aliasName => $aliasType,
				  alias => $arguments->{id},
				  uuid => $cpd->id()
				});
	    }
	}
	return $cpd;
    }

    # Checking for id uniqueness within scope of another aliasType, if passed
    foreach my $aliasType (@{$arguments->{mergeto}}) {

	#define whether a column in table is available that matches merging namespace
	my $matchingId=$arguments->{id};
	$matchingId=$arguments->{lc($aliasType)}[0] if(exists($arguments->{lc($aliasType)}));

	$cpd = $self->getObjectByAlias("compounds",$matchingId,$aliasType);
	if (defined($cpd)) {
	    Bio::KBase::ObjectAPI::utilities::verbose("Compound found with matching id ".$matchingId." for namespace ".$aliasType);
	    $self->addAlias({ attribute => "compounds",
			      aliasName => $arguments->{namespace},
			      alias => $arguments->{id},
			      uuid => $cpd->id()
			    });
	    if($arguments->{addmergealias}){
		foreach my $otherAliasType (@{$arguments->{mergeto}}){
		    next if $otherAliasType eq $aliasType;
		    $self->addAlias({ attribute => "compounds",
				      aliasName => $otherAliasType,
				      alias => $arguments->{id},
				      uuid => $cpd->id()
				    });
		}
	    }
	    return $cpd;
	}
    }

    #Special case of checking for protons
    if(($arguments->{namespace} eq "ModelSEED" && $arguments->{id} eq "cpd00067") ||
       ($arguments->{namespace} eq "KEGG" && $arguments->{id} eq "C00080") ||
       ($arguments->{namespace} =~ /Cyc$/ && $arguments->{id} eq "PROTON") ||
       (scalar( grep { $_ =~ /^protons?$/i } @{$arguments->{names}} )>0)){
	$cpd=$self->checkForProton();
	if(defined($cpd)){
	    Bio::KBase::ObjectAPI::utilities::verbose("Proton found: ".$arguments->{id}.":".join("|",@{$arguments->{names}}));
	    $self->addAlias({ attribute => "compounds",
			      aliasName => $arguments->{namespace},
			      alias => $arguments->{id},
			      uuid => $cpd->id()
			    });
	    if($arguments->{addmergealias}){
		foreach my $aliasType (@{$arguments->{mergeto}}){
		    $self->addAlias({ attribute => "compounds",
				      aliasName => $aliasType,
				      alias => $arguments->{id},
				      uuid => $cpd->id()
				    });
		}
	    }
	    return $cpd;
	}
    }

    #Special case of checking for water
    if(($arguments->{namespace} eq "ModelSEED" && $arguments->{id} eq "cpd00001") ||
       ($arguments->{namespace} eq "KEGG" && $arguments->{id} eq "C00001") ||
       ($arguments->{namespace} =~ /Cyc$/ && $arguments->{id} eq "WATER") ||
       (scalar( grep { $_ =~ /^water$/i } @{$arguments->{names}} )>0)){
	$cpd=$self->checkForWater();
	if(defined($cpd)){
	    Bio::KBase::ObjectAPI::utilities::verbose("Water found: ".$arguments->{id}.":".join("|",@{$arguments->{names}}));
	    $self->addAlias({ attribute => "compounds",
			      aliasName => $arguments->{namespace},
			      alias => $arguments->{id},
			      uuid => $cpd->id()
			    });
	    if($arguments->{addmergealias}){
		foreach my $aliasType (@{$arguments->{mergeto}}){
		    $self->addAlias({ attribute => "compounds",
				      aliasName => $aliasType,
				      alias => $arguments->{id},
				      uuid => $cpd->id()
				    });
		}
	    }
	    return $cpd;
	}
    }

    #Checking for match by name if requested
    if (defined($arguments->{matchbyname}) && $arguments->{matchbyname} == 1) {
	foreach my $name (@{$arguments->{names}}) {
	    #Rule is only one unique searchname allowed, and to look for it in aliasSet
	    my $searchname = Bio::KBase::ObjectAPI::KBaseBiochem::Compound::nameToSearchname($name);
	    if($self->queryObject("aliasSets",{name=>"searchname"})){
		$cpd = $self->getObjectByAlias("compounds",$searchname,"searchname");
	    }

	    #if not found, try the MS::Compound::searchnames() function
	    if(!$cpd){
		$cpd = $self->queryObject("compounds",{searchnames => $searchname});
	    }

	    if (defined($cpd)){
		Bio::KBase::ObjectAPI::utilities::verbose("Compound (".$arguments->{id}.") matched based on name ".$name);
		
		$self->addAlias({attribute => "compounds",
				 aliasName => $arguments->{namespace},
				 alias => $arguments->{id},
				 uuid => $cpd->id()
				});
		if($arguments->{addmergealias}){
		    foreach my $aliasType (@{$arguments->{mergeto}}){
			$self->addAlias({ attribute => "compounds",
					  aliasName => $aliasType,
					  alias => $arguments->{id},
					  uuid => $cpd->id()
					});
		    }
		}
		return $cpd;
	    }
	}
    }

    # Actually creating compound
    Bio::KBase::ObjectAPI::utilities::verbose("Creating compound ".$arguments->{id});

    $cpd = $self->add("compounds",{id => $arguments->{id},
				   name => $arguments->{names}[0],
				   abbreviation => $arguments->{abbreviation},
				   formula => $arguments->{formula},
				   mass => $arguments->{mass},
				   defaultCharge => $arguments->{charge},
				   deltaG => $arguments->{deltag},
				   deltaGErr => $arguments->{deltagerr},
    			   pkas => $arguments->{pkas},
    			   pkbs => $arguments->{pkbs}});

    # Adding id as alias
    $self->addAlias({attribute => "compounds",
		     aliasName => $arguments->{namespace},
		     alias => $arguments->{id},
		     uuid => $cpd->id()});

    if($arguments->{addmergealias}){
	foreach my $aliasType (@{$arguments->{mergeto}}){
	    $self->addAlias({attribute => "compounds",
			     aliasName => $aliasType,
			     alias => $arguments->{id},
			     uuid => $cpd->id()});
	}
    }

    #Adding alternative names as aliases
    #Adding searchnames as *unique* aliases
    foreach my $name (@{$arguments->{names}}) {
	$self->addAlias({attribute => "compounds",
			 aliasName => "name",
			 alias => $name,
			 uuid => $cpd->id()});

	my $searchname = $cpd->nameToSearchname($name);
	if(!$self->getObjectByAlias("compounds",$searchname,"searchname")){
	    $self->addAlias({attribute => "compounds",
			     aliasName => "searchname",
			     alias => $searchname,
			     uuid => $cpd->id()});
	}
    }
    return $cpd;
}

=head3 addReactionFromHash
Definition:
	Bio::KBase::ObjectAPI::KBaseBiochem::Compound = Bio::KBase::ObjectAPI::KBaseBiochem::Compound->addReactionFromHash({[]});
Description:
	This command adds a single reaction from an input hash

=cut

sub addReactionFromHash {
    my ($self,$arguments) = @_;
	$arguments = Bio::KBase::ObjectAPI::utilities::args(["equation","id"], {
	    names => undef,
	    equationAliasType => "id",
	    reactionIDaliasType => "ModelSEED",
	    direction => "=",
	    deltag => 10000000,
	    deltagerr => 10000000,
	    enzymes => [],
	    autoadd => 0,
	    addmergealias => 0,
	    balancedonly => 0,
	    findmatch=>1}, $arguments);

	# Remove names that are too long
	#$arguments->{names} = [ grep { length($_) < 255 } @{$arguments->{names}} ];
        $arguments->{names} = [$arguments->{id}] unless defined $arguments->{names}[0];
        $arguments->{abbreviation} = [$arguments->{id}] unless defined $arguments->{abbreviation};

	#Checking for id uniqueness
	my $rxn = $self->getObjectByAlias("reactions",$arguments->{id},$arguments->{reactionIDaliasType});
	if (defined($rxn)) {
		Bio::KBase::ObjectAPI::utilities::verbose("Reaction found with matching id ".$arguments->{id}." for namespace ".$arguments->{reactionIDaliasType});
		if($arguments->{addmergealias}){
		    foreach my $aliasType (@{$arguments->{mergeto}}){
			$self->addAlias({ attribute => "reactions",
					  aliasName => $aliasType,
					  alias => $arguments->{id},
					  uuid => $rxn->id()
					});
		    }
		}
		return $rxn;
	}

	# Checking for id uniqueness within scope of another aliasType, if passed
        foreach my $aliasType (@{$arguments->{mergeto}}){
	    $rxn = $self->getObjectByAlias("reactions",$arguments->{id},$aliasType);
	    if( defined($rxn) ){
			Bio::KBase::ObjectAPI::utilities::verbose("Reaction found with matching id ".$arguments->{id}." for namespace ".$aliasType);
			#Alias needs to be created for original namespace if found in different namespace
			$self->addAlias({
			    attribute => "reactions",
			    aliasName => $arguments->{reactionIDaliasType},
			    alias => $arguments->{id},
			    uuid => $rxn->id()
			});

			if($arguments->{addmergealias}){
			    foreach my $otherAliasType (@{$arguments->{mergeto}}){
				next if $otherAliasType eq $aliasType;
				$self->addAlias({ attribute => "reactions",
						  aliasName => $otherAliasType,
						  alias => $arguments->{id},
						  uuid => $rxn->id()
						});
			    }
			}
			return $rxn;
	    }
	}
	# Creating reaction from equation
	$rxn = Bio::KBase::ObjectAPI::KBaseBiochem::Reaction->new({
	    id=> $arguments->{id},
	    name => $arguments->{names}[0],
	    abbreviation => $arguments->{abbreviation},
	    direction => $arguments->{direction},
	    deltaG => $arguments->{deltag},
	    deltaGErr => $arguments->{deltagerr},
	    status => "OK",
	    thermoReversibility => "=",
	    defaultProtons => '0.0'
	});
	# Attach biochemistry object to reaction object
	$rxn->parent($self);
	# Parse the equation string to finish defining the reaction object
	# a return of zero indicates that the reaction was rejected
	if(!$rxn->loadFromEquation({
	    equation => $arguments->{equation},
	    aliasType => $arguments->{equationAliasType},
	    autoadd => $arguments->{autoadd},
	    rxnId => $arguments->{id},
	    compartment => $arguments->{compartment}
	})) {
	    Bio::KBase::ObjectAPI::utilities::verbose("Reaction ".$arguments->{id}." was rejected");
	    return undef;
	}else{
	    #Bio::KBase::ObjectAPI::utilities::verbose("Reaction ".$arguments->{id}." passed: ".$rxn->equationCode());
	}

    if($arguments->{findmatch}){
	# Generate equation search string and check to see if reaction not already in database
	my $code = $rxn->equationCode();
	my $searchRxn = $self->queryObject("reactions",{equationCode => $code});

    #attempt reverse string in case
	if (!defined($searchRxn)){
		$code = $rxn->revEquationCode();
		$searchRxn = $self->queryObject("reactions",{equationCode => $code});
	}
	if (defined($searchRxn)) {
	    # Check to see if searchRxn has alias from same namespace
	    my $alias = $searchRxn->getAlias($arguments->{reactionIDaliasType});
	    my $aliasSetName=$arguments->{reactionIDaliasType};
	    # If not, need to find any alias to use (avoiding names for now)
	    if(!$alias){
		foreach my $set ( grep { $_  ne "name" && $_ ne "searchname" && $_ ne "Enzyme Class"} keys %{$self->reactionsByAlias()}){
		    $alias=$searchRxn->getAlias($set);
		    last if $alias;
		}
		# Fall back onto name
		if(!$alias){
		    $alias=$searchRxn->name();
		    $aliasSetName="could not find ID";
		}
	    }
	    Bio::KBase::ObjectAPI::utilities::verbose("Reaction ".$alias." (".$aliasSetName.") found with matching equation for Reaction ".$arguments->{id});
	    $self->addAlias({ attribute => "reactions",
			      aliasName => $arguments->{reactionIDaliasType},
			      alias => $arguments->{id},
			      uuid => $searchRxn->id()
			    });
	    if($arguments->{addmergealias}){
		foreach my $aliasType (@{$arguments->{mergeto}}){
		    $self->addAlias({ attribute => "reactions",
				      aliasName => $aliasType,
				      alias => $arguments->{id},
				      uuid => $searchRxn->id()
				    });
		}
	    }
	    return $searchRxn;
	}
    }

    #if balancerxn option checked
    #then do $rxn->checkReactionMassChargeBalance()
    #and only add reaction if it passes those checks
    #saves having to delete the reaction too
    if($arguments->{balancedonly}==1){
	my $result = $rxn->checkReactionMassChargeBalance({rebalanceProtons=>1,saveStatus=>1});

	if($result->{balanced}==0 && (defined($result->{error}) || defined($result->{imbalancedAtoms}))){
	    Bio::KBase::ObjectAPI::utilities::verbose("Rejecting: ".$rxn->id()." based on status: ".$rxn->status());
	    return;
	}
    }

    Bio::KBase::ObjectAPI::utilities::verbose("Creating reaction ".$rxn->uuid()." (".$arguments->{id}.")");

	# Attach reaction to biochemistry
	$self->add("reactions", $rxn);
	$self->addAlias({
		attribute => "reactions",
		aliasName => $arguments->{reactionIDaliasType},
		alias => $arguments->{id},
		uuid => $rxn->id()
	});
    if($arguments->{addmergealias}){
        foreach my $aliasType (@{$arguments->{mergeto}}){
	    $self->addAlias({ attribute => "reactions",
			      aliasName => $aliasType,
			      alias => $arguments->{id},
			      uuid => $rxn->id()
			    });
	}
    }
	for (my $i=0;$i < @{$arguments->{names}}; $i++) {
		$self->addAlias({
			attribute => "reactions",
			aliasName => "name",
			alias => $arguments->{names}[$i],
			uuid => $rxn->id()
		});
	}
	for (my $i=0;$i < @{$arguments->{enzymes}}; $i++) {
		$self->addAlias({
			attribute => "reactions",
			aliasName => "Enzyme Class",
			alias => $arguments->{enzymes}[$i],
			uuid => $rxn->id()
		});
	}
	return $rxn;
}

=head3 searchForStimuli

Definition:
	Bio::KBase::ObjectAPI::Stimuli = Bio::KBase::ObjectAPI::Biochemistry->searchForStimuli(string id);
Description:
	Searches for the input Stimuli in the biochemistry

=cut

sub searchForStimuli {
    my ($self,$id) = @_;
	#First search by exact alias match
	my $obj = $self->getObjectByAlias("stimuli",$id);
	#Next, search by name
	if (!defined($obj)) {
		$obj = $self->queryObject("stimuli",{abbreviation => $id});
	}
	if (!defined($obj)) {
		$obj = $self->queryObject("stimuli",{name => $id});
	}
	if (!defined($obj)) {
		my $cpd = $self->searchForCompound($id);
		if (defined($cpd)) {
			$obj = $self->queryObject("stimuli",{compound_uuid => $cpd->uuid()});
		}
	}
	return $obj;
}

=head3 searchForCompound
Definition:
	Bio::KBase::ObjectAPI::KBaseBiochem::Compound = Bio::KBase::ObjectAPI::KBaseBiochem::Compound->searchForCompound(string);
Description:
	Searches for a compound by ID, name, or alias.

=cut

sub searchForCompound {
	my ($self,$compound) = @_;
	#First search by exact alias match
	my $cpdobj = $self->getObjectByAlias("compounds",$compound);
	#Next, search by name
	if (!defined($cpdobj)) {
		my $searchname = Bio::KBase::ObjectAPI::KBaseBiochem::Compound->nameToSearchname($compound);
		$cpdobj = $self->queryObject("compounds",{searchnames => $searchname});
	}
	return $cpdobj;
}

=head3 searchForAllCompounds
Definition:
	[ Bio::KBase::ObjectAPI::KBaseBiochem::Compound ] = Bio::KBase::ObjectAPI::KBaseBiochem::Compound->searchForAllCompounds(string);
Description:
	Searches for a compound by ID, name, or alias and returns all matches.

=cut

sub searchForAllCompounds {
	my ($self,$compound) = @_;
	#First search by exact alias match
	my $cpds = $self->getObjectsByAlias("compounds",$compound);
	#Next, search by name
	if (!defined($cpds->[0])) {
		my $searchname = Bio::KBase::ObjectAPI::KBaseBiochem::Compound->nameToSearchname($compound);
		$cpds = $self->queryObjects("compounds",{searchnames => $searchname});
	}
	return $cpds;
}

=head3 searchForReaction
Definition:
	Bio::KBase::ObjectAPI::KBaseBiochem::Reaction = Bio::KBase::ObjectAPI::KBaseBiochem::Reaction->searchForReaction(string);
Description:
	Searches for a reaction by ID, name, or alias.

=cut

sub searchForReaction {
	my ($self,$id) = @_;
	#First search by exact alias match
	my $rxnobj = $self->getObjectByAlias("reactions",$id);
	#Next, search by name
	if (!defined($rxnobj)) {
		$rxnobj = $self->queryObject("reactions",{name => $id});
	}
	if (!defined($rxnobj)) {
		$rxnobj = $self->queryObject("reactions",{uuid => $id});
	}
	return $rxnobj;
}

=head3 searchForAllReactions
Definition:
	[ Bio::KBase::ObjectAPI::KBaseBiochem::Reaction ] = Bio::KBase::ObjectAPI::KBaseBiochem::Reaction->searchForAllReactions(string);
Description:
	Searches for a reaction by ID, name, or alias and returns all matches.

=cut

sub searchForAllReactions {
	my ($self,$id) = @_;
	#First search by exact alias match
	my $rxns = $self->getObjectsByAlias("reactions",$id);
	#Next, search by name
	if (!defined($rxns->[0])) {
		$rxns = $self->queryObjects("reactions",{name => $id});
	}
	if (!defined($rxns)) {
		$rxns = $self->queryObjects("reactions",{uuid => $id});
	}
	return $rxns;
}

=head3 searchForReactionByCode
Definition:
	{rxnobj => ,dir => } = Bio::KBase::ObjectAPI::KBaseBiochem::searchForReactionByCode(string);
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

=head3 searchForCompartment
Definition:
	Bio::KBase::ObjectAPI::KBaseBiochem::Compartment = Bio::KBase::ObjectAPI::KBaseBiochem::Compartment->searchForCompartment(string);
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

=head3 mergeBiochemistry
Definition:
	void mergeBiochemistry(Bio::KBase::ObjectAPI::KBaseBiochem::Biochemistry,{});
Description:
	This command merges the input biochemistry into the current biochemistry

=cut

sub mergeBiochemistry {
    my ($self,$bio,$opts) = @_;
    my $typelist = [
	        "cues",
		"compartments",
		"compounds",
		"reactions",
		"media",
		"compoundSets",
		"reactionSets",
    ];
    my $types = {
    	"cues" => "checkForDuplicateCue",
    	"compartments" => "checkForDuplicateCompartment",
    	"compounds" => "checkForDuplicateCompound",
    	"reactions" => "checkForDuplicateReaction",
    	"media" => "checkForDuplicateMedia",
    	"compoundSets" => "checkForDuplicateCompoundSet",
    	"reactionSets" => "checkForDuplicateReactionSet"
    };

    foreach my $type (@{$typelist}) {
    	my $func = $types->{$type};
    	my $objs = $bio->$type();
	if($type eq "compounds" && !$opts->{consolidate} && defined($opts->{mergevia})){
	    $objs=$bio->sortObjectsByNamespace("compounds",$opts->{mergevia},$bio);
	}
    	my $uuidTranslation = {};
    	$opts->{touched}={};
	Bio::KBase::ObjectAPI::utilities::verbose("Merging ".scalar(@$objs)." ".$type." from ".$bio->name()." with ".scalar(@{$self->$type()})." from ".$self->name());
    	for (my $j=0; $j < @{$objs}; $j++) {
		    my $obj = $objs->[$j];
		    my $aliases={};
		    if(!defined($opts->{noaliastransfer})){
			foreach my $set ( grep { $_->attribute() eq $type } @{$bio->aliasSets()} ){
			    foreach my $alias ( @{$obj->getAliases($set->name())} ){
				$aliases->{$set->name()}{$alias}=1;
			    }
			}
		    }

		    my $objId="";
		    if($type eq "cues"){
			$objId=$obj->name();
		    }else{
			$objId=$obj->id();
		    }
		    foreach my $idNamespace (@{$opts->{namespace}}){
			if(exists($aliases->{$idNamespace})){
			    $objId=(keys %{$aliases->{$idNamespace}})[0];
			    last;
			}
		    }

		    if ($type eq "reactions") {
				$obj->parent($self);
		    }

		    my $dupObj = $self->$func($obj,$opts);
		    if ( defined($dupObj) ){
			my $dupObjId="";
			if($type eq "cues"){
			    $dupObjId=$dupObj->name();
			}else{
			    $dupObjId=$dupObj->id();
			}

			Bio::KBase::ObjectAPI::utilities::verbose("Duplicate ".substr($type,0,-1)." found; ".$objId." merged to ".$dupObjId);

			foreach my $aliasName (keys %$aliases){
			    foreach my $alias (keys %{$aliases->{$aliasName}}){
				if($aliasName eq "searchname" && $self->getObjectByAlias("compounds",$alias,"searchname")){
				    Bio::KBase::ObjectAPI::utilities::verbose("Skipping searchname ".$alias." as its already present");
				}else{
				    Bio::KBase::ObjectAPI::utilities::verbose("Adding alias ".$alias." from ".$aliasName." for ".$dupObj->uuid()); 
				    $self->addAlias({attribute=>$type,aliasName=>$aliasName,alias=>$alias,uuid=>$dupObj->uuid()});
				}
			    }
			}

			if($type eq "compounds" && $dupObj->formula() eq "noformula" && $obj->formula() ne "noformula"){
			    Bio::KBase::ObjectAPI::utilities::verbose("Copying over formula from $objId to $dupObjId\n");

			    $dupObj->formula($obj->formula());
			    $dupObj->defaultCharge($obj->defaultCharge());
			    $dupObj->mass($obj->mass());
			    $dupObj->unchargedFormula($obj->unchargedFormula());
				
			}

			if($type eq "compounds" && $dupObj->deltaG() == 10000000 && $obj->deltaG() ne 10000000){
			    Bio::KBase::ObjectAPI::utilities::verbose("Copying over thermodynamics from $objId to $dupObjId\n");
			    
			    $dupObj->cues($obj->cues());
			    $dupObj->deltaG($obj->deltaG());
			    $dupObj->deltaGErr($obj->deltaGErr());

			}

			$uuidTranslation->{$obj->uuid()} = $dupObj->uuid();
			$opts->{touched}{$dupObj->uuid()}{$obj->uuid()}=1;
			$obj->uuid($dupObj->uuid());
		    } else {
			Bio::KBase::ObjectAPI::utilities::verbose("Adding new ".substr($type,0,-1)." (".$objId.") to biochemistry");
			foreach my $aliasName (keys %$aliases){
			    foreach my $alias (keys %{$aliases->{$aliasName}}){
				if($aliasName eq "searchname" && $self->getObjectByAlias("compounds",$alias,"searchname")){
				    Bio::KBase::ObjectAPI::utilities::verbose("Skipping searchname ".$alias." as its already present\n");
				}else{
				    $self->addAlias({attribute=>$type,aliasName=>$aliasName,alias=>$alias,uuid=>$obj->uuid()});
				}
			    }
			}
			$self->add($type,$obj);
		    }
    	}
    	$bio->updateLinks($type,$uuidTranslation,1,1);
    	$bio->_clearIndex();
    	$self->updateLinks($type,$uuidTranslation,1,1);
    	$self->_clearIndex();
    }
}

=head3 checkForDuplicateAliasSet
Definition:
	void checkForDuplicateAliasSet(Bio::KBase::ObjectAPI::AliasSet);
Description:
	This command checks if the input aliasSet is a duplicate for an existing aliasSet

=cut

sub checkForDuplicateAliasSet {
    my ($self,$obj,$opts) = @_;
    return $self->queryObject("aliasSets",{
    	name => $obj->name(),
    	class => $obj->class(),
    	attribute => $obj->attribute()
    });
}

=head3 checkForDuplicateReactionSet
Definition:
	void checkForDuplicateReactionSet(Bio::KBase::ObjectAPI::KBaseBiochem::Media);
Description:
	This command checks if the input media is a duplicate for an existing media

=cut

sub checkForDuplicateReactionSet {
    my ($self,$obj,$opts) = @_;
    return $self->queryObject("reactionSets",{reactionCodeList => $obj->reactionCodeList()});
}

=head3 checkForDuplicateCompoundSet
Definition:
	void checkForDuplicateCompoundSet(Bio::KBase::ObjectAPI::KBaseBiochem::Media);
Description:
	This command checks if the input media is a duplicate for an existing media

=cut

sub checkForDuplicateCompoundSet {
    my ($self,$obj,$opts) = @_;
    return $self->queryObject("compoundSets",{compoundListString => $obj->compoundListString()});
}

=head3 checkForDuplicateMedia
Definition:
	void checkForDuplicateMedia(Bio::KBase::ObjectAPI::KBaseBiochem::Media);
Description:
	This command checks if the input media is a duplicate for an existing media

=cut

sub checkForDuplicateMedia {
    my ($self,$obj,$opts) = @_;
    return $self->queryObject("media",{compoundListString => $obj->compoundListString()});
}

=head3 checkForDuplicateReaction
Definition:
	void checkForDuplicateReaction(Bio::KBase::ObjectAPI::KBaseBiochem::Reaction);
Description:
	This command checks if the input reaction is a duplicate for an existing reaction

=cut

sub checkForDuplicateReaction {
    my ($self,$obj,$opts) = @_;
    my $code = $obj->equationCode();
    my $result = $self->queryObject("reactions",{equationCode => $code});
    
    if(!$result){
	$code = $obj->revEquationCode();
	$result = $self->queryObject("reactions",{equationCode => $code});
    }

    return $result;
}

=head3 checkForDuplicateCompound
Definition:
	void checkForDuplicateCompound(Bio::KBase::ObjectAPI::KBaseBiochem::Compound);
Description:
	This command checks if the input compound is a duplicate for an existing compound

=cut

sub checkForDuplicateCompound {
    my ($self,$obj,$opts) = @_;
    if(defined($opts->{mergevia})){
	foreach my $mergeNamespace (@{$opts->{mergevia}}){
	    next if !$obj->getAlias($mergeNamespace);
	    foreach my $alias (@{$obj->getAliases($mergeNamespace)}){
		my $dupObj = $self->getObjectByAlias("compounds",$alias,$mergeNamespace);
		if($dupObj && ( !exists($opts->{touched}{$dupObj->uuid()}) || defined($opts->{consolidate}) )){
		    Bio::KBase::ObjectAPI::utilities::verbose("Duplicate compound found using $alias in $mergeNamespace");
		    return $dupObj;
		}
	    }
	}
	return undef;
    }
    return undef if !$obj->name();
    return $self->queryObject("compounds",{name => $obj->name()});
}

=head3 sortObjectsByNamespace
Definition:
	void sortObjectsByNamespace(string,arrayref,arrayref);
Description:
	This command re-sorts objects according to whether they have aliases.
        Only works for compounds and reactions
=cut

sub sortObjectsByNamespace {
    my ($self,$type,$aliasNames,$biochem) = @_;
    my $bio=$self;
    $bio=$biochem if $biochem;

    my @newObjOrder=();
    my %touchedObjs=();
    
    foreach my $aliasName (@$aliasNames){
	my $set = $bio->queryObject("aliasSets",{name=>$aliasName,attribute=>$type});
	if(!$set){
	    print STDERR "Warning: $aliasName not found\n";
	    next;
	}
	my $aliases = $set->aliases();
	foreach my $alias (sort keys %$aliases){
	    foreach my $uuid (@{$aliases->{$alias}}){
		my $obj=$bio->getObject($type,$uuid);
		if(!$obj){
		    print STDERR "Object $uuid not found for $alias in set $aliasName\n";
		    next;
		}
		push(@newObjOrder,$bio->getObject($type,$uuid)) if !exists($touchedObjs{$uuid});
		$touchedObjs{$uuid}=1;
	    }
	}
    }

    if(scalar(@newObjOrder) != scalar(@{$bio->$type()})){
	my $objs=$bio->$type();
	foreach my $obj (@$objs){
	    push(@newObjOrder, $obj) if !exists($touchedObjs{$obj->uuid()});
	}
    }

    return \@newObjOrder;
}

=head3 checkForDuplicateCompartment
Definition:
	void checkForDuplicateCompartment(Bio::KBase::ObjectAPI::KBaseBiochem::Cue);
Description:
	This command checks if the input compartment is a duplicate for an existing compartment

=cut

sub checkForDuplicateCompartment {
    my ($self,$obj,$opts) = @_;
    return $self->queryObject("compartments",{name => $obj->name()});
}

=head3 checkForDuplicateCue
Definition:
	void checkForDuplicateCue(Bio::KBase::ObjectAPI::KBaseBiochem::Cue);
Description:
	This command checks if the input cue is a duplicate for an existing cue

=cut

sub checkForDuplicateCue {
    my ($self,$obj,$opts) = @_;
    return $self->queryObject("cues",{name => $obj->name()});
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

__PACKAGE__->meta->make_immutable;
1;
