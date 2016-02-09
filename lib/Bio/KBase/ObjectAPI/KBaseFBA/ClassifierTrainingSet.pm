########################################################################
# Bio::KBase::ObjectAPI::KBaseFBA::ClassifierTrainingSet - This is the moose object corresponding to the KBaseFBA.ClassifierTrainingSet object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2014-08-26T21:34:17
########################################################################
use strict;
use Bio::KBase::ObjectAPI::KBaseFBA::DB::ClassifierTrainingSet;
package Bio::KBase::ObjectAPI::KBaseFBA::ClassifierTrainingSet;
use Moose;
use namespace::autoclean;
extends 'Bio::KBase::ObjectAPI::KBaseFBA::DB::ClassifierTrainingSet';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has jobID => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildjobid' );
has jobPath => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildjobpath' );
has jobDirectory => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildjobdirectory' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildjobid {
	my ($self) = @_;
	my $path = $self->jobPath();
	my $jobid = Bio::KBase::ObjectAPI::utilities::CurrentJobID();
	if (!defined($jobid)) {
		my $fulldir = File::Temp::tempdir(DIR => $path);
		if (!-d $fulldir) {
			File::Path::mkpath ($fulldir);
		}
		$jobid = substr($fulldir,length($path."/")-1);
	}
	return $jobid
}

sub _buildjobpath {
	my ($self) = @_;
	my $path = Bio::KBase::ObjectAPI::config::mfatoolkit_job_dir();
	if (!defined($path) || length($path) == 0) {
		$path = "/tmp/fbajobs/";
	}
	if (!-d $path) {
		File::Path::mkpath ($path);
	}
	return $path;
}

sub _buildjobdirectory {
	my ($self) = @_;
	return $self->jobPath().$self->jobID()."/";
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub load_trainingset {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args([],{
		reload => 0
	}, @_);
	if ($self->attribute_type() eq "functional_roles") {
		my $wsg = $self->workspace_training_set();
		for (my $i=0; $i < @{$wsg}; $i++) {
			if (@{$wsg->[$i]->[3]} == 0 || $args->{reload} == 1) {
				my $g = $self->getLinkedObject($wsg->[$i]->[0]);
				my $rh = $g->rolehash();
				$wsg->[$i]->[3] = [keys(%{$rh})];
			}
		}
		my $eg = $self->external_training_set();
		for (my $i=0; $i < @{$eg}; $i++) {
			print "Processing ".$i." of ".@{$eg}."\n";
			if (@{$wsg->[$i]->[3]} == 0 || $args->{reload} == 1) {
				my $rh;
				if ($eg->[$i]->[0] eq "seed") {
					require "ModelSEED/Client/SAP.pm";
					my $sapsvr = ModelSEED::Client::SAP->new();
					my $featureHash = $sapsvr->all_features({-ids => $eg->[$i]->[1]});
					my $functions = $sapsvr->ids_to_functions({-ids => $featureHash->{$eg->[$i]->[1]}});
					for (my $j=0;$j < @{$featureHash->{$eg->[$i]->[1]}}; $j++) {
						my $roles = [split(/\s*;\s+|\s+[\@\/]\s+/,$functions->{$featureHash->{$eg->[$i]->[1]}->[$j]})];
						for (my $k=0; $k < @{$roles}; $k++) {
							push(@{$rh->{$roles->[$k]}},$featureHash->{$eg->[$i]->[1]}->[$j]); 
						}
					}			
				} elsif ($eg->[$i]->[0] eq "kbase") {
					require "Bio/KBase/CDMI/CDMIClient.pm";
					my $cdmi = Bio::KBase::CDMI::CDMIClient->new_for_script();
					#TODO
				}
				$eg->[$i]->[3] = [keys(%{$rh})];
			}
		}
	}
}

sub create_job_directory {
	my $self = shift;
	my $dir = $self->jobDirectory();
	my $classdata;
	my $attdata;
	my $classlist;
	my $wsg = $self->workspace_training_set();
	for (my $i=0; $i < @{$wsg}; $i++) {
		push(@{$classdata},$wsg->[$i]->[0]."\t".$wsg->[$i]->[1]);
		for (my $j=0; $j < @{$wsg->[$i]->[3]}; $j++) {
			push(@{$attdata},$wsg->[$i]->[0]."\t".$wsg->[$i]->[2]->[$j]);
		}
	}
	my $eg = $self->external_training_set();
	for (my $i=0; $i < @{$eg}; $i++) {
		push(@{$classdata},$eg->[$i]->[0]."/".$eg->[$i]->[1]."\t".$eg->[$i]->[2]);
		for (my $j=0; $j < @{$eg->[$i]->[3]}; $j++) {
			push(@{$attdata},$eg->[$i]->[0]."/".$eg->[$i]->[1]."\t".$eg->[$i]->[3]->[$j]);
		}
	}
	my $classes = $self->class_data();
	for (my $i=0; $i < @{$classes}; $i++) {
		push(@{$classlist},$classes->[$i]->[0])
	}	
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($dir."class.txt",$classdata);
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($dir."classes.txt",$classlist);
	Bio::KBase::ObjectAPI::utilities::PRINTFILE($dir."attributes.txt",$attdata);
}

sub runjob {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["classifier"],{}, @_);
	$self->load_trainingset();
	$self->create_job_directory();
	system("java -jar ".Bio::KBase::ObjectAPI::utilities::CLASSIFIER_PATH()."WekaClassifierCreator.jar ".$self->jobDirectory()." ".$args->{classifier});
	my $cf = $self->load_classifier({type => $args->{classifier}});
	if (defined(Bio::KBase::ObjectAPI::config::FinalJobCache())) {
		if (!-d Bio::KBase::ObjectAPI::config::FinalJobCache()) {
			File::Path::mkpath (Bio::KBase::ObjectAPI::config::FinalJobCache());
		}
		system("cd ".$self->jobPath().";tar -czf ".Bio::KBase::ObjectAPI::config::FinalJobCache()."/".$self->jobID().".tgz ".$self->jobID());
	}
	if ($self->jobDirectory() =~ m/\/fbajobs\/.+/) {
		File::Path::rmtree($self->jobDirectory());
	}
	return $cf;
}

sub load_classifier {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args(["type"],{}, @_);
	my $classifier = Bio::KBase::ObjectAPI::utilities::LOADFILE($self->jobDirectory()."classifier.txt");
	my $performance = Bio::KBase::ObjectAPI::utilities::LOADFILE($self->jobDirectory()."performance.txt");
	my $readable = Bio::KBase::ObjectAPI::utilities::LOADFILE($self->jobDirectory()."readableModel.txt");
	my $object = {
		id => $self->id().".classifier",
        attribute_type => $self->attribute_type(),
        classifier_type => $args->{type},
        trainingset_ref => $self->_reference(),
        data => join("\n",@{$classifier}),
        readable => join("\n",@{$readable}),
        classes => []
	};
	for (my $i=0; $i < @{$performance}; $i++) {
		if ($performance->[$i] =~ m/Correctly\sClassified\sInstances\s+(\d+)\s/) {
			$object->{correctly_classified_instances} = $1;
		} elsif ($performance->[$i] =~ m/Incorrectly\sClassified\sInstances\s+(\d+)\s/) { 
			$object->{incorrectly_classified_instances} = $1;
		} elsif ($performance->[$i] =~ m/Kappa\sstatistic\s+([\d\.]+)$/) { 
			$object->{kappa} = $1;
		} elsif ($performance->[$i] =~ m/Mean\sabsolute\serror\s+([\d\.]+)$/) { 
			$object->{mean_absolute_error} = $1;
		} elsif ($performance->[$i] =~ m/Root\smean\ssquared\serror\s+([\d\.]+)$/) { 
			$object->{root_mean_squared_error} = $1;
		} elsif ($performance->[$i] =~ m/Relative\sabsolute\serror\s+([\d\.]+)\s/) { 
			$object->{relative_absolute_error} = $1;
		} elsif ($performance->[$i] =~ m/Root\srelative\ssquared\serror\s+([\d\.]+)\s/) { 
			$object->{relative_squared_error} = $1;
		} elsif ($performance->[$i] =~ m/Detailed\sAccuracy\sBy\sClass/) { 
			$i += 3;
			while ($i < @{$performance}) {
				if ($performance->[$i] =~ m/Weighted\sAvg/) {
					last;
				} elsif ($performance->[$i] =~ m/([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)\s+([\d\.]+)\s+(\w[\w+\s]+)$/) {
					my $indecies = {$7 => @{$object->{classes}}-1};
					push(@{$object->{classes}},{
						id => $7,
        				description => "none",
        				tp_rate => $1+0,
						fb_rate => $2+0,
						precision => $3+0,
						recall => $4+0,
						f_measure => $5+0,
						ROC_area => $6+0,
						missclassifications => {},
					});
				}
				$i++;
			}
			last;
		}
	}
	$object->{total_instances} = $object->{incorrectly_classified_instances}+$object->{correctly_classified_instances};
	my $cf = Bio::KBase::ObjectAPI::KBaseFBA::Classifier->new($object);
	return $cf;
}

sub load_trainingset_from_input {
	my $self = shift;
	my $args = Bio::KBase::ObjectAPI::utilities::args([],{
		workspace_training_set => [],
    	external_training_set => [],
    	description => undef,
    	source => undef,
    	class_data => [],
    	attribute_type => "functional_roles",
    	preload_attributes => 0,
	}, @_);
	my $classdata = {};
    for (my $i=0; $i < @{$args->{class_data}}; $i++) {
    	push(@{$self->class_data()},$args->{class_data}->[$i]);
    	$classdata->{$args->{class_data}->[$i]->[0]} = 1;
    }
    for (my $i=0; $i < @{$args->{workspace_training_set}}; $i++) {
    	$args->{workspace_training_set}->[$i]->[3] = [];
    	if (!defined($args->{workspace_training_set}->[$i]->[2])) {
    		$args->{workspace_training_set}->[$i]->[2] = "unknown";
    	}
    	push(@{$self->workspace_training_set()},$args->{workspace_training_set}->[$i]);
    	if (!defined($classdata->{$args->{workspace_training_set}->[$i]->[2]})) {
    		push(@{$self->class_data()},[$args->{workspace_training_set}->[$i]->[2],"none"]);
    		$classdata->{$args->{workspace_training_set}->[$i]->[2]} = 1;
    	}
    }
    for (my $i=0; $i < @{$args->{external_training_set}}; $i++) {
    	$args->{external_training_set}->[$i]->[3] = [];
    	if (!defined($args->{external_training_set}->[$i]->[2])) {
    		$args->{external_training_set}->[$i]->[2] = "unknown";
    	}
    	push(@{$self->external_training_set()},$args->{external_training_set}->[$i]);
    	if (!defined($classdata->{$args->{external_training_set}->[$i]->[2]})) {
    		push(@{$self->class_data()},[$args->{external_training_set}->[$i]->[2],"none"]);
    		$classdata->{$args->{external_training_set}->[$i]->[2]} = 1;
    	}
    }
    if (defined($args->{source})) {
    	$self->source($args->{source});
    }
    if (defined($args->{attribute_type})) {
    	$self->attribute_type($args->{attribute_type});
    }
    if (defined($args->{description})) {
    	$self->description($args->{description});
    }
    if ($args->{preload_attributes} == 1) {
    	$self->load_trainingset();	
    }
}

__PACKAGE__->meta->make_immutable;
1;
