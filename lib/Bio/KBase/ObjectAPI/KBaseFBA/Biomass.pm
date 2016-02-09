########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::Biomass - This is the moose object corresponding to the Biomass object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::Biomass;
package Bio::KBase::ObjectAPI::KBaseFBA::Biomass;
use Moose;
use Bio::KBase::ObjectAPI::utilities;
use namespace::autoclean;
use POSIX qw(floor ceil);
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::Biomass';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has definition => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_definition' );
has modelequation => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_modelequation' );
has equation => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_equation' );
has rescaledEquation  => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_rsequation' );
has equationCode => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_equationcode' );
has mapped_uuid  => ( is => 'rw', isa => 'ModelSEED::uuid',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_mapped_uuid' );
has id  => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_id' );
has "index"  => ( is => 'rw', isa => 'Int',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_index' );
#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
# _equation_builder : builds a biomass equation from a configuration
# format : type of ids to use, default uuid
# hashed : boolean, if true, return a md5 sum of the string in place of the string
sub _equation_builder {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args([], {
        format => "uuid",
        hashed => 0,
        rescale => 0
    }, @_);
    my $cpds = $self->biomasscompounds();
    my $rgtHash;
    my $blacklistCpd = {
    	cpd17043_c0 => 1,
    	cpd17041_c0 => 1,
    	cpd11416_c0 => 1,
    	cpd17042_c0 => 1
    };
    for (my $i=0; $i < @{$cpds}; $i++) {
        my $id = $cpds->[$i]->modelcompound()->compound()->id();
        my $coef = $cpds->[$i]->coefficient();
        if ($args->{rescale} == 1) {
	        if (!defined($blacklistCpd->{$cpds->[$i]->modelcompound()->id()})) {
		        if ($coef > 10) {
		        	my $redisual = ceil($cpds->[$i]->coefficient()) - $cpds->[$i]->coefficient();
		        	if ($redisual > 0.5) {
		        		$redisual = $redisual-1;
		        	}
		        	$coef = $coef-$redisual*1;
		        } elsif ($coef < -10) {
		        	my $redisual = ceil($cpds->[$i]->coefficient()) - $cpds->[$i]->coefficient();
		        	if ($redisual > 0.5) {
		        		$redisual = $redisual-1;
		        	}
		        	$coef = $coef-$redisual*1;
		        } else {
		        	$coef = 1*$coef;
		        }
	        }
        }
        if ($args->{format} eq "name" || $args->{format} eq "id") {
            my $function = $args->{format};
            $id = $cpds->[$i]->modelcompound()->compound()->$function();
        } elsif ($args->{format} eq "modelid") {
        	$id = $cpds->[$i]->modelcompound()->id();
        } elsif ($args->{format} ne "uuid") {
            $id = $cpds->[$i]->modelcompound()->compound()->getAlias($args->{format});
        }
        if (!defined($rgtHash->{$id}->{$cpds->[$i]->modelcompound()->modelcompartment()->id()})) {
            $rgtHash->{$id}->{$cpds->[$i]->modelcompound()->modelcompartment()->id()} = 0;
        }
        $rgtHash->{$id}->{$cpds->[$i]->modelcompound()->modelcompartment()->id()} += $coef;
    }
    my $reactcode = "";
    my $productcode = "";
    my $sign = "=>";
    my $sortedCpd = [sort(keys(%{$rgtHash}))];
    for (my $i=0; $i < @{$sortedCpd}; $i++) {
        my $indecies = [sort(keys(%{$rgtHash->{$sortedCpd->[$i]}}))];
        for (my $j=0; $j < @{$indecies}; $j++) {
            my $compartment = "";
            if ($args->{format} ne "modelid") {
            #if ($indecies->[$j] ne "c0" && $args->{format} ne "modelid") {
                $compartment = "[".$indecies->[$j]."]";
            }
            if ($rgtHash->{$sortedCpd->[$i]}->{$indecies->[$j]} < 0) {
                my $coef = -1*$rgtHash->{$sortedCpd->[$i]}->{$indecies->[$j]};
                if (length($reactcode) > 0) {
                    $reactcode .= "+";
                }
                $reactcode .= "(".$coef.")".$sortedCpd->[$i].$compartment;
            } elsif ($rgtHash->{$sortedCpd->[$i]}->{$indecies->[$j]} > 0) {
                if (length($productcode) > 0) {
                    $productcode .= "+";
                }
                $productcode .= "(".$rgtHash->{$sortedCpd->[$i]}->{$indecies->[$j]}.")".$sortedCpd->[$i].$compartment;
            }
        }
    }
    if ($args->{hashed} == 1) {
        return Digest::MD5::md5_hex($reactcode.$sign.$productcode);
    }
    return $reactcode.$sign.$productcode;
}

# _parse_equation_string :
#     given a string, return an arrayref with the following hashes:
#
#     {
#         compound    => string,
#         compartment => string,
#         coefficient => float,
#     }
# TODO : MS::Bimoass _parse_equation_string compartment isn't right ... need to capture [\S^\]]
# TODO : MS::Bimoass _parse_equation_string compound needs to capture more than alphanumeric
sub _parse_equation_string {
    my ($self, $string) = @_;
    my $reagents = [];
    my @TempArray = split(/\s/, $string);
    my $CurrentlyOnReactants = 1;
    my $coefficient = 1;
    for (my $i = 0; $i < @TempArray; $i++) {
        # Coefficient strings (123.4) or 123.4
        if ($TempArray[$i] =~ m/^\(([\.\d]+)\)$/ ||
            $TempArray[$i] =~ m/^([\.\d]+)$/ ) {
            $coefficient = $1;
        # reactant strings are anything else
        } elsif ( $TempArray[$i] =~ m/(^[a-zA-Z0-9]+)/ ) {
            $coefficient *= -1 if ($CurrentlyOnReactants);
            my $compound    = $1;
            my $compartment = "c0";
            # match compound[comparment]
            if ( $TempArray[$i] =~ m/^[a-zA-Z0-9]+\[([a-zA-Z]+)\]/ ) {
                $compartment = lc($1);
                if ( length($compartment) == 1 ) {
                    $compartment .= "0";
                }
            }
            # push onto array
            push(@$reagents, {
                compound => $compound,
                compartment => $compartment,
                coefficient => $coefficient,
            });
            # reset coefficient
            $coefficient = 1;
        # switch flag for reactant / product sign
        } elsif ($TempArray[$i] =~ m/=/) {
            $CurrentlyOnReactants = 0;
        }
    }
    return $reagents;
}



sub _build_definition {
    my ($self) = @_;
    return $self->_equation_builder({format=>"name",hashed=>0});
}

sub _build_equation {
    my ($self) = @_;
    return $self->_equation_builder({format=>"id",hashed=>0});
}

sub _build_modelequation {
    my ($self) = @_;
    return $self->_equation_builder({format=>"modelid",hashed=>0});
}

sub _build_equationcode {
    my ($self,$args) = @_;
    return $self->_equation_builder({format=>"uuid",hashed=>1});
}

sub _build_rsequation {
    my ($self,$args) = @_;
    return $self->_equation_builder({format=>"id",hashed=>0,rescale => 1});
}

sub _build_mapped_uuid {
    my ($self) = @_;
    return "00000000-0000-0000-0000-000000000000";
}
sub _build_id {
    my ($self) = @_;
    my $prefix = "bio";
    return sprintf("${prefix}%05d", $self->index);
}

sub _build_index {
    my ($self) = @_;
    my $index = 1;
    if (defined($self->parent())) {
        my $biomasses = $self->parent->biomasses;
        map { $_->index($index); $index++ } @$biomasses;
    }
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
=head3 adjustBiomassReaction

Definition:
	Bio::KBase::ObjectAPI::KBaseFBA::Biomass->adjustBiomassReaction({
		coefficient => float
		modelcompound => Bio::KBase::ObjectAPI::KBaseFBA::ModelCompound
	});
Description:
	Modifies the biomass reaction to adjust a compound, add a compound, or remove a compound
	
=cut
sub adjustBiomassReaction {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["modelcompound","coefficient"],{}, @_);
	my $biocpds = $self->biomasscompounds();
	my $found = 0;
	for (my $i=0; $i < @{$biocpds}; $i++) {
		my $biocpd = $biocpds->[$i];
		if ($biocpd->modelcompound()->id() eq $args->{modelcompound}->id()) {
			if ($args->{coefficient} == 0) {
				$self->remove("biomasscompounds",$biocpd);
			} else {
				$found = 1;
				$biocpd->coefficient($args->{coefficient});
			}
		}
	}
	if ($args->{coefficient} != 0 && $found == 0) {
		$self->add("biomasscompounds",{
			modelcompound_ref => "~/modelcompounds/id/".$args->{modelcompound}->id(),
			coefficient => $args->{coefficient}
		});
	}
}

=head3 loadFromEquation

Definition:
	[string]:Missing compounds = Bio::KBase::ObjectAPI::KBaseFBA::Biomass->loadFromEquation({
		equation => string,
		aliasType => string,
		addMissingCompounds => 0/1
	});
Description:
	Converts the input equation string into a biomass reaction object
	
=cut
sub loadFromEquation {
    my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["equation"],{
    	aliasType => undef,
    	addMissingCompounds => 0
    }, @_);
    my $mod = $self->parent();
    my $bio = $self->parent()->biochemistry();
    my $reagentHashes = $self->_parse_equation_string($args->{equation});
    my $missingCompounds = [];
    foreach my $reagent (@$reagentHashes) {
        my $compound    = $reagent->{compound};
        my $compartment = $reagent->{compartment};
        my $coefficient = $reagent->{coefficient};
        my $comp = $mod->queryObject("modelcompartments",{label => $compartment});
        if (!defined($comp)) {
            Bio::KBase::ObjectAPI::utilities::USEWARNING("Unrecognized compartment '".$compartment."' used in biomass equation!");
            my $biocompid = substr($compartment,0,1);
            my $compindex = substr($compartment,1,1);
            my $biocomp = $bio->queryObject("compartments",{id => $biocompid});
            if (!defined($biocomp)) {
                $biocomp = $bio->add("compartments",{
                    id => $biocompid,
                    name => $biocompid,
                    hierarchy => 3
                });
            }
            $comp = $mod->add("modelcompartments",{
                compartment_ref => $biocomp->_reference(),
                compartmentIndex => $compindex,
                label => $compartment,
                pH => 7,
                potential => 0
            });
        }
        my $cpd;
        if (!defined($args->{aliasType})) {
        	$cpd = $bio->searchForCompound($compound);
        } elsif ($args->{aliasType} eq "uuid" || $args->{aliasType} eq "name") {
            $cpd = $bio->queryObject("compounds",{$args->{aliasType} => $compound});
        } else {
            $cpd = $bio->getObjectByAlias("compounds",$compound,$args->{aliasType});
        }
        if (!defined($cpd)) {
            Bio::KBase::ObjectAPI::utilities::USEWARNING("Unrecognized compound '".$compound."' used in biomass equation!");
            if ($args->{addMissingCompounds} == 1) {
	            $cpd = $bio->add("compounds",{
	                name => $compound,
	                abbreviation => $compound
	            });
            } else {
            	push(@{$missingCompounds},$compound);
            }
        }
        if (defined($cpd)) {
	        my $modcpd = $mod->queryObject("modelcompounds",{
	            compound_ref => $cpd->_reference(),
	            modelcompartment_ref => "~/modelcompartments/id/".$comp->id()
	        });
	        if (!defined($modcpd)) {
	            $modcpd = $mod->add("modelcompounds",{
	                compound_uuid => $cpd->uuid(),
	                charge => $cpd->defaultCharge(),
	                formula => $cpd->formula(),
	                modelcompartment_ref => "~/modelcompartments/id/".$comp->id()
	            });
	        }
	        $self->add("biomasscompounds",{
	        	modelcompound_ref => "~/modelcompounds/id/".$modcpd->id(),
	        	coefficient => $coefficient,
	        });
        }
    }
    return $missingCompounds;
}

sub ImportExternalEquation {
	my $self = shift;
    my $args = Bio::KBase::ObjectAPI::utilities::args(["reagents"],{}, @_);
	my $bio = $self->parent()->template()->biochemistry();
    my $biocpds = $self->biomasscompounds();
    for (my $i=0; $i < @{$biocpds}; $i++){
    	$self->remove("biomasscompounds",$biocpds->[$i])
    }
    $self->biomasscompounds([]);
    if (!defined($args->{reagents}->{cpd11416_c0})) {
    	my $mdlcpd = $self->parent()->searchForCompound("cpd11416_c0");
    	if (!defined($mdlcpd)) {
    		$mdlcpd = $self->parent()->add("modelcompounds",{
   				id => "cpd11416_c0",
				compound_ref => $bio->getObject("compounds","cpd11416")->_reference(),
				name => "Biomass_c0",
				charge => 0,
				formula => "",
				modelcompartment_ref => "~/modelcompartments/id/c0",
				aliases => []
   			});
    	}
    	$args->{reagents}->{cpd11416_c0} = 1;
    }
    foreach my $key (keys(%{$args->{reagents}})) {
    	$self->add("biomasscompounds",{
	    	modelcompound_ref => "~/modelcompounds/id/".$key,
			coefficient => $args->{reagents}->{$key}
	    });
    }
}

__PACKAGE__->meta->make_immutable;
1;
