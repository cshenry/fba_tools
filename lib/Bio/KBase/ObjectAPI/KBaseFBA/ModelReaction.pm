########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction - This is the moose object corresponding to the ModelReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelReaction;
package Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction;
use Moose;
use Bio::KBase::ObjectAPI::utilities;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::ModelReaction';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has equation => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildequation' );
has code => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildequationcode' );
has definition => ( is => 'rw', isa => 'Str',printOrder => '3', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_builddefinition' );
has revEquationCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildrevequationcode' );
has name => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildname' );
has abbreviation => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildabbreviation' );
has modelCompartmentLabel => ( is => 'rw', isa => 'Str',printOrder => '4', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmodelCompartmentLabel' );
has gprString => ( is => 'rw', isa => 'Str',printOrder => '6', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildgprString' );
has exchangeGPRString => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildexchangeGPRString' );
has missingStructure => ( is => 'rw', isa => 'Bool',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmissingStructure' );
has biomassTransporter => ( is => 'rw', isa => 'Bool',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildbiomassTransporter' );
has isTransporter => ( is => 'rw', isa => 'Bool',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildisTransporter' );
has translatedDirection  => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildtranslatedDirection' );
has featureIDs  => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildfeatureIDs' );
has featureUUIDs  => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildfeatureUUIDs' );
has equationCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildequationcode' );
has revEquationCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildrevequationcode' );
has equationCompFreeCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompfreeequationcode' );
has revEquationCompFreeCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildrevcompfreeequationcode' );
has genEquationCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildgenequationcode' );
has revGenEquationCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildgenrevequationcode' );
has equationFormula => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildequationformula' );
has complexString => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcomplexString' );
has stoichiometry => ( is => 'rw', isa => 'ArrayRef', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildstoichiometry' );

has reaction => (is => 'rw', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_reaction', clearer => 'clear_reaction', isa => 'Ref', weak_ref => 1);

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _build_reaction {
	 my ($self) = @_;
	 if ($self->reaction_ref() !~ m/_[a-z]/) {
	 	my $array = [split(/_/,$self->id())];
	 	my $comp = pop(@{$array});
	 	$comp =~ s/\d+//;
	 	$array = [split(/\//,$self->reaction_ref())];
	 	my $rxnid = pop(@{$array});
	 	$self->reaction_ref("~/template/reactions/id/".$rxnid."_".$comp);
	 }
	 my $rxn = $self->getLinkedObject($self->reaction_ref());
	 if (!defined($rxn)) {
	 	my $ref = $self->reaction_ref();
	 	$ref =~ s/_e/_c/;
	 	$self->reaction_ref($ref);
	 	$rxn = $self->getLinkedObject($self->reaction_ref());
	 }
	 if (!defined($rxn)) {
	 	$rxn = $self->getLinkedObject("~/template/reactions/id/rxn00000_c");
	 	if (!defined($rxn)) {
		 	$rxn = $self->parent()->template()->add("reactions",{
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
sub _buildname {
	my ($self) = @_;
	return $self->reaction->msname()."_".$self->modelCompartmentLabel();
}
sub _buildabbreviation {
	my ($self) = @_;
	return $self->reaction->msabbreviation()."_".$self->modelCompartmentLabel();
}
sub _builddefinition {
	my ($self) = @_;
	return $self->createEquation({format=>"name"});
}

sub _buildequation {
	my ($self) = @_;
	return $self->createEquation({format=>"id"});
}

sub _buildequationcode {
	my ($self) = @_;
	return $self->createEquation({indecies => 0,format=>"id",hashed=>1,protons=>0,direction=>0});
}

sub _buildrevequationcode {
	my ($self) = @_;
	return $self->createEquation({indecies => 0,format=>"id",hashed=>1,protons=>0,reverse=>1,direction=>0});
}
sub _buildgenequationcode {
	my ($self) = @_;
	return $self->createEquation({format=>"id",hashed=>1,protons=>0,direction=>0,generalized=>1});
}
sub _buildgenrevequationcode {
	my ($self) = @_;
	return $self->createEquation({format=>"id",hashed=>1,protons=>0,reverse=>1,direction=>0,generalized=>1});
}

sub _buildcompfreeequationcode {
	my ($self) = @_;
	return $self->createEquation({indecies => 0,format=>"id",hashed=>1,compts=>0});
}

sub _buildrevcompfreeequationcode {
	my ($self) = @_;
	return $self->createEquation({indecies => 0,format=>"id",hashed=>1,compts=>0,reverse=>1});
}

sub _buildequationformula {
    my ($self,$args) = @_;
    return $self->createEquation({indecies => 0,format=>"formula",hashed=>0,water=>0});
}

sub _buildmodelCompartmentLabel {
	my ($self) = @_;
	return $self->modelcompartment()->id();
}
sub _buildgprString {
	my ($self) = @_;
	my $gprs = [];
	my $allUnknown = 1;
	foreach my $protein (@{$self->modelReactionProteins()}) {
	    my $one_gpr = $protein->gprString();
	    if ( $one_gpr ne "Unknown" ) {
		$allUnknown = 0;
	    }
	    push(@$gprs, $protein->gprString());
	}
	my $gpr = "";
	# Account for possibility that all of the multiple reaction proteins are empty.
	if ( $allUnknown == 1 ) {
	    $gpr = "Unknown";
	    return $gpr;
	}
	foreach my $one_gpr (@$gprs) {
	    # Avoid printing GPRs that look like (unknown or GENE) if one modelReactionProtein is empty and another has genes in it.
	    if ( $one_gpr eq "Unknown" ) { next; }
	    if (length($gpr) > 0) {
		$gpr .= " or ";	
	    }
	    $gpr .= $one_gpr;
	}
	if (@{$self->modelReactionProteins()} > 1) {
		$gpr = "(".$gpr.")";	
	}
	if (length($gpr) == 0) {
		$gpr = "Unknown";
	}
	return $gpr;
}
sub _buildexchangeGPRString {
	my ($self) = @_;
	my $gpr = "MSGPR{";
	foreach my $protein (@{$self->modelReactionProteins()}) {
		if (length($gpr) > 6) {
			$gpr .= "/";	
		}
		$gpr .= $protein->exchangeGPRString();
	}
	$gpr .= "}";
	return $gpr;
}
sub _buildmissingStructure {
	my ($self) = @_;
	my $rgts = $self->modelReactionReagents();
	for (my $i=0; $i < @{$rgts}; $i++) {
		my $rgt = $rgts->[$i];
		if (@{$rgt->modelcompound()->compound()->structures()} == 0) {
			return 1;	
		}
	}
	return 0;
}
sub _buildbiomassTransporter {
	my ($self) = @_;
	my $rgts = $self->modelReactionReagents();
	for (my $i=0; $i < @{$rgts}; $i++) {
		my $rgt = $rgts->[$i];
		if ($rgt->modelcompound()->isBiomassCompound() == 1) {
			for (my $j=$i+1; $j < @{$rgts}; $j++) {
				my $rgtc = $rgts->[$j];
				if ($rgt->modelcompound()->compound_ref() eq $rgtc->modelcompound()->compound_ref()) {
					if ($rgt->modelcompound()->modelcompartment_ref() ne $rgtc->modelcompound()->modelcompartment_ref()) {
						return 1;
					}
				}
			}
		}
	}
	return 0;
}
sub _buildisTransporter {
	my ($self) = @_;
	my $rgts = $self->modelReactionReagents();
	my $initrgt = $rgts->[0];
	for (my $i=1; $i < @{$rgts}; $i++) {
		my $rgt = $rgts->[$i];
		if ($rgt->modelcompound()->modelcompartment_ref() ne $initrgt->modelcompound()->modelcompartment_ref()) {
			return 1;	
		}
	}
	return 0;
}

sub _buildtranslatedDirection {
	my ($self) = @_;
	if ($self->direction() eq "=") {
		return "<=>";	
	} elsif ($self->direction() eq ">") {
		return "=>";
	} elsif ($self->direction() eq "<") {
		return "<=";
	}
	return $self->direction();
}
sub _buildfeatureIDs {
	my ($self) = @_;
	my $featureHash = {};
	foreach my $protein (@{$self->modelReactionProteins()}) {
		foreach my $subunit (@{$protein->modelReactionProteinSubunits()}) {
			foreach my $gene (@{$subunit->features()}) {
				$featureHash->{$gene->id()} = 1;
			}
		}
	}
	return [keys(%{$featureHash})];
}
sub _buildfeatureUUIDs {
	my ($self) = @_;
	my $featureHash = {};
	foreach my $protein (@{$self->modelReactionProteins()}) {
		foreach my $subunit (@{$protein->modelReactionProteinSubunits()}) {
			foreach my $gene (@{$subunit->features()}) {
				$featureHash->{$gene->_reference()} = 1;
			}
		}
	}
	return [keys(%{$featureHash})];
}
sub _buildcomplexString {
	my ($self) = @_;
	my $complexString = "";
	foreach my $protein (@{$self->modelReactionProteins()}) {
		my $sustring = "";
		foreach my $subunit (@{$protein->modelReactionProteinSubunits()}) {
			my $genestring = "";
			foreach my $gene (@{$subunit->features()}) {
				if (length($genestring) > 0) {
					$genestring .= "=";
				}
				$genestring .= $gene->id();
			}
			if (length($genestring) > 0) {
				if (length($sustring) > 0) {
					$sustring .= "+";
				}
				$sustring .= $genestring;
			}
		}
		if (length($sustring) > 0) {
			if (length($complexString) > 0) {
				$complexString .= "&";
			}
			$complexString .= $sustring;
		}
	}
	return $complexString;
}
sub _buildstoichiometry {
	my ($self) = @_;
	my $stoichiometry = [];
	foreach my $reagent (@{$self->modelReactionReagents()}) {
		push(@{$stoichiometry},[$reagent->coefficient(),$reagent->modelcompound()->name(),$reagent->modelcompound()->id()]);
	}
	return $stoichiometry;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub reaction_expression {
	my ($self,$expression_hash) = @_;
	my $highest_expression = 0;
	foreach my $protein (@{$self->modelReactionProteins()}) {
		my $protexp = $protein->protein_expression($expression_hash);
		if ($protexp > $highest_expression) {
			$highest_expression = $protexp;
		}
	}
	return $highest_expression;
}

sub kegg {
    my ($self,$id) = @_;
    if (defined($id)) {
    	my $aliases = $self->aliases();
    	for (my $i=0; $i < @{$aliases}; $i++) {
    		if ($aliases->[$i] eq "KEGG:".$id) {
    			return $id;
    		}
    	}
    	push(@{$aliases},"KEGG:".$id);
    }
    my $aliases = $self->getAliases("KEGG");
    return (@$aliases) ? $aliases->[0] : undef;
}

sub enzyme {
    my ($self,$enzyme) = @_;
    if (defined($enzyme)) {
    	my $aliases = $self->aliases();
    	for (my $i=0; $i < @{$aliases}; $i++) {
    		if ($aliases->[$i] eq "EC:".$enzyme) {
    			return $enzyme;
    		}
    	}
    	push(@{$aliases},"EC:".$enzyme);
    }
    my $aliases = $self->getAliases("EC");
    return (@$aliases) ? $aliases->[0] : undef;
}

sub getAlias {
    my ($self,$set) = @_;
    my $aliases = $self->getAliases($set);
    return (@$aliases) ? $aliases->[0] : undef;
}

sub getAliases {
    my ($self,$setName) = @_;
    return [] unless(defined($setName));
    my $output = [];
    my $aliases = $self->aliases();
    for (my $i=0; $i < @{$aliases}; $i++) {
    	if ($aliases->[$i] =~ m/$setName:(.+)/) {
    		push(@{$output},$1);
    	} elsif ($aliases->[$i] !~ m/:/ && $setName eq "name") {
    		push(@{$output},$aliases->[$i]);
    	}
    }
    return $output;
}

sub allAliases {
	my ($self) = @_;
    my $output = [];
    my $aliases = $self->aliases();
    for (my $i=0; $i < @{$aliases}; $i++) {
    	if ($aliases->[$i] =~ m/(.+):(.+)/) {
    		push(@{$output},$2);
    	} else {
    		push(@{$output},$aliases->[$i]);
    	}
    }
    return $output;
}

sub hasAlias {
    my ($self,$alias,$setName) = @_;
    my $aliases = $self->aliases();
    for (my $i=0; $i < @{$aliases}; $i++) {
    	if (defined($setName) && $aliases->[$i] eq $setName.":".$alias) {
    		return 1;
    	} elsif (!defined($setName) && $aliases->[$i] eq $alias) {
    		return 1;
    	}
    }
    return 0;
}

sub addAlias {
    my ($self,$alias,$setName) = @_;
    my $aliases = $self->aliases();
    for (my $i=0; $i < @{$aliases}; $i++) {
    	if (defined($setName) && $aliases->[$i] eq $setName.":".$alias) {
    		return ;
    	} elsif (!defined($setName) && $aliases->[$i] eq $alias) {
    		return ;
    	}
    }
    if (defined($setName)) {
    	push(@{$aliases},$setName.":".$alias);
    } else {
    	push(@{$aliases},$alias);
    }
}

=head3 createEquation
Definition:
	string = Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction->createEquation({
		format => string(id),
		hashed => 0/1(0)
	});
Description:
	Creates an equation for the model reaction with compounds specified according to the input format

=cut

sub createEquation {
    my ($self,$args) = @_;
    $args = Bio::KBase::ObjectAPI::utilities::args([], { indecies => 1,
							 format => 'id',
                                                         hashed => 0,
                                                         water => 1,
							 compts=>1,
							 reverse=>0,
							 direction=>1,
							 protons => 1,
							 generalized => 0,
							 stoichiometry => 0}, $args);
	
	my $rgts = $self->modelReactionReagents();
	my $rgtHash;
    my $rxnCompID = $self->modelcompartment()->compartment()->id();
    my $hcpd = $self->parent()->template()->checkForProton();
 	if (!defined($hcpd) && $args->{hashed}==1) {
	    Bio::KBase::ObjectAPI::utilities::error("Could not find proton in biochemistry!");
	}
	my $wcpd = $self->parent()->template()->checkForWater();
 	if (!defined($wcpd) && $args->{water}==1) {
	    Bio::KBase::ObjectAPI::utilities::error("Could not find water in biochemistry!");
	}
	
	for (my $i=0; $i < @{$rgts}; $i++) {
		my $rgt = $rgts->[$i];
		my $id = $rgt->modelcompound()->compound()->id();
		if ($id eq "cpd00000") {
			$id = $rgt->modelcompound()->id();
		}

		next if $args->{protons} == 0 && $id eq $hcpd->id() && !$self->isTransporter();
		next if $args->{water} == 0 && $id eq $wcpd->id();

		if (!defined($rgtHash->{$id}->{$rgt->modelcompound()->modelcompartment()->id()})) {
			$rgtHash->{$id}->{$rgt->modelcompound()->modelcompartment()->id()} = 0;
		}
		$rgtHash->{$id}->{$rgt->modelcompound()->modelcompartment()->id()} += $rgt->coefficient();
		$rgtHash->{$id}->{"name"} = $rgt->modelcompound()->name();
	}

    my @reactcode = ();
    my @productcode = ();
    my $sign = " <=> ";

    if($args->{direction}==1){
	$sign = " => " if $self->direction() eq ">";
	$sign = " <= " if $self->direction() eq "<";
    }
	
    my %FoundComps=();
    my $CompCount=0;

    my $sortedCpd = [sort(keys(%{$rgtHash}))];
    for (my $i=0; $i < @{$sortedCpd}; $i++) {

	#Cpds sorted on original modelseed identifiers
	#But representative strings collected here (if not 'id')
	my $printId=$sortedCpd->[$i];

	if($args->{format} ne "id"){
	    my $cpd;
	    my $rgts = $self->modelReactionReagents();
	    for (my $j=0; $j < @{$rgts}; $j++) {
	    	if ($printId eq $rgts->[$j]->modelcompound()->compound()->id()) {
	    		$cpd = $rgts->[$j]->modelcompound()->compound();
	    	}
	    }
	    if (!defined($cpd)) {
	    	for (my $j=0; $j < @{$rgts}; $j++) {
		    	if ($printId eq $rgts->[$j]->modelcompound()->id()) {
		    		$cpd = $rgts->[$j]->modelcompound();
		    	}
		    }
	    }

	    if($args->{format} eq "name"){
		$printId = $cpd->name();
	    } elsif($args->{format} ne "uuid" && $args->{format} ne "formula") {
		$printId = $cpd->getAlias($args->{format});
	    }elsif($args->{format} eq "formula"){
		$printId = $cpd->formula();
	    }
	}

	my $comps = [sort(keys(%{$rgtHash->{$sortedCpd->[$i]}}))];
	for (my $j=0; $j < @{$comps}; $j++) {
	    if ($comps->[$j] =~ m/([a-z])(\d+)/) {
		my $comp = $1;
		my $index = $2;
		my $compartment = $comp;

		if($args->{generalized} && !exists($FoundComps{$comp})){
		    $compartment = $CompCount;
		    $FoundComps{$comp}=$CompCount;
		    $CompCount++;
		}elsif($args->{generalized} && exists($FoundComps{$comp})){
		    $compartment = $FoundComps{$comp};
		}
		
		if ($args->{indecies} == 0) {
		    $compartment = "[".$compartment."]" if !$args->{stoichiometry};
		}else{
		    $compartment = "[".$compartment.$index."]" if !$args->{stoichiometry};
		}

		$compartment= "" if !$args->{compts};

		if ($rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]} < 0) {
		    my $coef = -1*$rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]};
		    my $reactcode = "(".$coef.") ".$printId.$compartment;
			if($args->{stoichiometry}==1){
		    	my $name = $rgtHash->{$sortedCpd->[$i]}->{name};
			    $coef = $rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]};
			    $reactcode = join(":",($coef,$printId,$compartment,'0',"\"".$name."\""));
			}
		    push(@reactcode,$reactcode);

		} elsif ($rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]} > 0) {
		    my $coef = $rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]};
		    
		    my $productcode .= "(".$coef.") ".$printId.$compartment;
			if($args->{stoichiometry}==1){
			    my $name = $rgtHash->{$sortedCpd->[$i]}->{name};
			    $productcode = join(":",($coef,$printId,$compartment,'0',"\"".$name."\""));
			}
		    push(@productcode, $productcode);
		}
	    }
	}
    }
    

    my $reaction_string = join(" + ",@reactcode).$sign.join(" + ",@productcode);

	if($args->{stoichiometry} == 1){
		$reaction_string = join(";",@reactcode,@productcode);
	}

    if($args->{reverse}==1){
	$reaction_string = join(" + ",@productcode).$sign.join(" + ",@reactcode);
    }

    if ($args->{hashed} == 1) {
	return Digest::MD5::md5_hex($reaction_string);
    }
    return $reaction_string;
}

=head3 hasModelReactionReagent
Definition:
	boolean = Bio::KBase::ObjectAPI::KBaseFBA::ModelReaction->hasModelReactionReagent(string(uuid));
Description:
	Checks to see if a model reaction contains a reagent

=cut

sub hasModelReactionReagent {
    my ($self,$mdlcpd_id) = @_;
    my $rgts = $self->modelReactionReagents();
    if (!defined($rgts->[0])) {
	return 0;	
    }
    for (my $i=0; $i < @{$rgts}; $i++) {
	if ($rgts->[$i]->modelcompound()->id() eq $mdlcpd_id) {
	    return 1;
	}
    }
    return 0;
}

=head3 addReagentToReaction
Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::FBAModel = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->addReagentToReaction({
		coefficient => REQUIRED,
		modelcompound_ref => REQUIRED
	});
Description:
	Add a new ModelCompound object to the ModelReaction if the ModelCompound is not already in the reaction

=cut

sub addReagentToReaction {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["coefficient","modelcompound_ref"],{}, @_);
	my $rgts = $self->modelReactionReagents();
	for (my $i=0; $i < @{$rgts}; $i++) {
		if ($rgts->[$i]->modelcompound_ref() eq $args->{modelcompound_ref}) {
			return $rgts->[$i];
		}
	}
	my $mdlrxnrgt = $self->add("modelReactionReagents",{
		coefficient => $args->{coefficient},
		modelcompound_ref => $args->{modelcompound_ref}
	});
	return $mdlrxnrgt;
}

=head3 addModelReactionProtein
Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::FBAModel = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->addModelReactionProtein({
		proteinDataTree => REQUIRED:{},
		complex_uuid => REQUIRED:ModelSEED::uuid
	});
Description:
	Adds a new protein to the reaction based on the input data tree

=cut

sub addModelReactionProtein {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["proteinDataTree"], {complex_ref => ""}, @_);
	my $prots = $self->modelReactionProteins();
	for (my $i=0; $i < @{$prots}; $i++) {
		if ($prots->[$i]->complex_ref() eq $args->{complex_ref}) {
			return $prots->[$i];
		}
	}
	my $protdata = {complex_ref => $args->{complex_ref},modelReactionProteinSubunits => []};
	if (defined($args->{proteinDataTree}->{note})) {
		$protdata->{note} = $args->{proteinDataTree}->{note};
	}
	if (defined($args->{proteinDataTree}->{subunits})) {
		foreach my $subunit (keys(%{$args->{proteinDataTree}->{subunits}})) {
			my $data = {
				triggering => $args->{proteinDataTree}->{subunits}->{$subunit}->{triggering},
				optionalSubunit => $args->{proteinDataTree}->{subunits}->{$subunit}->{optionalSubunit},
				role => $subunit,
				feature_refs => [],
				note => ""
			};
			if (defined($args->{proteinDataTree}->{subunits}->{$subunit}->{note})) {
				$data->{note} = $args->{proteinDataTree}->{subunits}->{$subunit}->{note};
			}
			if (defined($args->{proteinDataTree}->{subunits}->{$subunit}->{genes})) {
				foreach my $gene (keys(%{$args->{proteinDataTree}->{subunits}->{$subunit}->{genes}})) {
					push(@{$data->{feature_refs}},$gene);
				}
			}
			push(@{$protdata->{modelReactionProteinSubunits}},$data);
		}
	}
	return $self->add("modelReactionProteins",$protdata);
}

=head3 setGPRFromArray
Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::FBAModel = Bio::KBase::ObjectAPI::KBaseFBA::FBAModel->setGPRFromArray({
		gpr => []
	});
Description:
	Sets the GPR of the reaction from three nested arrays

=cut

sub setGPRFromArray {
	my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["gpr"],{}, @_);
	$self->modelReactionProteins([]);
	foreach my $prot (@{$self->modelReactionProteins()}) {
		$self->remove("modelReactionProteins",$prot);
	}
	for (my $i=0; $i < @{$args->{gpr}}; $i++) {
    	if (defined($args->{gpr}->[$i]) && ref($args->{gpr}->[$i]) eq "ARRAY") {
	    	my $prot = $self->add("modelReactionProteins",{
	    		complex_ref => "",
	    		note => "Manually specified GPR"
	    	});
	    	for (my $j=0; $j < @{$args->{gpr}->[$i]}; $j++) {
	    		if (defined($args->{gpr}->[$i]->[$j]) && ref($args->{gpr}->[$i]->[$j]) eq "ARRAY") {
		    		for (my $k=0; $k < @{$args->{gpr}->[$i]->[$j]}; $k++) {
		    			if (defined($args->{gpr}->[$i]->[$j]->[$k])) {
						    my $featureId = $args->{gpr}->[$i]->[$j]->[$k];
						    my $ftrObj = $self->genome()->getObject("features",$featureId);
						    if (!defined($ftrObj)) {
								$prot->note($featureId);
						    }
						    else {
								my $subunit = $prot->add("modelReactionProteinSubunits",{
								    role => "",
								    triggering => 0,
								    optionalSubunit => 0,
								    note => "Manually specified GPR",
								    feature_refs => [$ftrObj->_reference()]
							    });
			    			}
			    		}
		    		}
	    		}
	    	}
    	}
    }
}

sub ImportExternalEquation {
	my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["reagents"],{}, @_);
    my $rxncpds = $self->modelReactionReagents();
    for (my $i=0; $i < @{$rxncpds}; $i++){
    	$self->remove("modelReactionReagents",$rxncpds->[$i])
    }
    $self->modelReactionReagents([]);
    foreach my $key (keys(%{$args->{reagents}})) {
    	$self->add("modelReactionReagents",{
	    	modelcompound_ref => "~/modelcompounds/id/".$key,
			coefficient => $args->{reagents}->{$key}
	    });
    }		
    my $output = $self->parent()->template()->searchForReactionByCode($self->equationCode());
    if (defined($output)) {
    	$self->reaction_ref($self->parent()->template()->_reference()."/reactions/id/".$output->{rxnobj}->id());
    	if ($output->{dir} eq "r") {
    		if ($self->direction() eq ">") {
    			$self->direction("<");
    		} elsif ($self->direction() eq "<") {
    			$self->direction(">");
    		}
    		my $rgts = $self->modelReactionReagents();
    		for (my $i=0; $i < @{$rgts}; $i++) {
    			$rgts->[$i]->coefficient(-1*$rgts->[$i]->coefficient());
    		}
    	}	
    } else {
    	print "Not found:".$self->id()."\n";
    	my $array = [split(/_/,$self->id())];
    	my $rxn = $self->parent()->template()->searchForReaction($array->[0]);
    	if (defined($rxn)) {
    		print $rxn->createEquation({format=>"msid",protons=>0,direction=>0})."\n";
    		print $self->createEquation({indecies => 0,format=>"msid",hashed=>0,protons=>0,direction=>0})."\n";
    	}
    	$self->reaction_ref($self->parent()->template()->_reference()."/reactions/id/rxn00000_c");
    }
}

sub loadGPRFromString {
	my $self = shift;
	my $gprstring = shift;
	my $geneAliases = $self->parent()->genome()->geneAliasHash();
	my $gpr = Bio::KBase::ObjectAPI::utilities::translateGPRHash(Bio::KBase::ObjectAPI::utilities::parseGPR($gprstring));
	my $missingGenes;
	for (my $m=0; $m < @{$gpr}; $m++) {
		my $protObj = $self->add("modelReactionProteins",{
			complex_ref => "",
			note => "Imported GPR",
			modelReactionProteinSubunits => []
		});		
		for (my $j=0; $j < @{$gpr->[$m]}; $j++) {
			my $subObj = $protObj->add("modelReactionProteinSubunits",{
				role => "",
				triggering => 0,
				optionalSubunit => 0,
				note => "Imported GPR",
				feature_refs => []
			});		
			for (my $k=0; $k < @{$gpr->[$m]->[$j]}; $k++) {
				my $ftrID = $gpr->[$m]->[$j]->[$k];
				if (!defined($geneAliases->{$ftrID})) {
					$missingGenes->{$ftrID} = 1;
				} else {
					$subObj->addLinkArrayItem("features",$geneAliases->{$ftrID});
				}
			}
		}
	}
}

__PACKAGE__->meta->make_immutable;
1;
