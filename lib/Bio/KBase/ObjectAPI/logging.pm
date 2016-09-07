package Bio::KBase::ObjectAPI::logging;
use strict;
use DateTime;

our $processid = undef;

our $handler;

sub set_handler {
	my ($input_handler) = @_;
	$handler = $input_handler;
}

sub processid {
	if (!defined($processid)) {
    	$processid = Data::UUID->new()->create_str();
    }
    return $processid;
}

sub log {
	my ($msg,$type) = @_;
	$handler->util_log($msg,$type,Bio::KBase::ObjectAPI::logging::processid());
}

1;
