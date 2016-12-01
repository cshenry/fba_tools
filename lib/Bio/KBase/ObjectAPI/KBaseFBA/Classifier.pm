########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::Classifier - This is the moose object corresponding to the Classifier object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-11-15T18:17:11
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::Classifier;
package Bio::KBase::ObjectAPI::KBaseFBA::Classifier;
use Moose;
use namespace::autoclean;
use Bio::KBase::ObjectAPI::utilities;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::Classifier';
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
sub classify_genomes {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["data"],{}, @_);
	my $ts = $args->{data};
	if ($ts->attribute_type() ne $self->attribute_type()) {
		$ts->attribute_type($self->attribute_type());
		$ts->load_trainingset({reload => 1});
	} else {
		$ts->load_trainingset();
	}
	$ts->create_job_directory();
	$self->print_classifier({directory => $ts->jobDirectory()});
	system("java -jar ".Bio::KBase::ObjectAPI::utilities::CLASSIFIER_PATH()."WekaClassifierEx.jar ".$ts->jobDirectory());
	my $cr = $self->load_classifier_result();
	if (defined(Bio::KBase::utilities::conf("ModelSEED","fbajobcache"))) {
		if (!-d Bio::KBase::utilities::conf("ModelSEED","fbajobcache")) {
			File::Path::mkpath (Bio::KBase::utilities::conf("ModelSEED","fbajobcache"));
		}
		system("cd ".$ts->jobPath().";tar -czf ".Bio::KBase::utilities::conf("ModelSEED","fbajobcache")."/".$ts->jobID().".tgz ".$ts->jobID());
	}
	if ($ts->jobDirectory() =~ m/\/fbajobs\/.+/) {
		File::Path::rmtree($ts->jobDirectory());
	}
	return $cr;
}

sub print_classifier {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["directory"],{}, @_);
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($args->{directory}."classifier.txt",[split("\n",$self->data())]);
}

sub load_classifier_result {
	my $self = shift;
}

__PACKAGE__->meta->make_immutable;
1;
