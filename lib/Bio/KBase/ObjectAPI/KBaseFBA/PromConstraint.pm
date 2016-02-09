########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::PromConstraint - This is the moose object corresponding to the KBaseFBA.PromConstraint object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-05-13T20:12:44
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::PromConstraint;
package Bio::KBase::ObjectAPI::KBaseFBA::PromConstraint;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::PromConstraint';
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
=head3 PrintPROMModel

Definition:
	void Bio::KBase::ObjectAPI::KBaseFBA::PromConstraint->PrintPROMModel();
Description:
	Prints PROM model data to FBA job directory for parsing in MFAToolkit

=cut

sub PrintPROMModel {
	my ($self,$filename) = @_;
	my $maps = $self->transcriptionFactorMaps();
	my $tfhash;
	for (my $i=0; $i < @{$maps}; $i++) {
		if ($maps->[$i]->transcriptionFactor_ref() =~ m/([^\/]+)$/) {
			my $tf = $1;
			$tf =~ s/\|/___/g;
			my $probs = $maps->[$i]->targetGeneProbs();
			for (my $j=0; $j < @{$probs}; $j++) {
				if ($probs->[$j]->target_gene_ref() =~ m/([^\/]+)$/) {
					my $gene = $1;
					$gene =~ s/\|/___/g;
					$tfhash->{$1}->{$tf} = [$probs->[$j]->probTGonGivenTFoff(),$probs->[$j]->probTGonGivenTFon()];
				}
			}
		}
	}
	open ( my $fh, ">", $filename);
	foreach my $gene (keys(%{$tfhash})) {
		print $fh $gene."\t";
		my $first = 1;
		foreach my $tf (keys(%{$tfhash->{$gene}})) {
			if ($first == 0) {
				print $fh ";";
			}
			$first = 0;
			print $fh $tf.":".$tfhash->{$gene}->{$tf}->[0].":".$tfhash->{$gene}->{$tf}->[1];
		}
		print $fh "\n";
	}
	close($fh);
}

__PACKAGE__->meta->make_immutable;
1;
