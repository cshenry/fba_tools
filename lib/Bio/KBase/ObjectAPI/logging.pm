package Bio::KBase::ObjectAPI::logging;
use strict;
use Bio::KBase::ObjectAPI::config;
use File::Path;
use DateTime;

our $logger = undef;
our $processid = undef;

sub processid {
	if (!defined($processid)) {
    	$processid = Data::UUID->new()->create_str();
    }
    return $processid;
}

sub logger {
	if (!defined($logger)) {
    	if (!-e Bio::KBase::ObjectAPI::config::config_directory()."/ProbModelSEED.conf") {
	    	if (!-d Bio::KBase::ObjectAPI::config::config_directory()) {
	    		File::Path::mkpath (Bio::KBase::ObjectAPI::config::config_directory());
	    	}
	    	Bio::KBase::ObjectAPI::utilities::PRINTFILE(Bio::KBase::ObjectAPI::config::config_directory()."ProbModelSEED.conf",[
		    	"############################################################",
				"# A simple root logger with a Log::Log4perl::Appender::File ",
				"# file appender in Perl.",
				"############################################################",
				"log4perl.rootLogger=INFO, LOGFILE",
				"",
				"log4perl.appender.LOGFILE=Log::Log4perl::Appender::File",
				"log4perl.appender.LOGFILE.filename=".Bio::KBase::ObjectAPI::config::config_directory()."ProbModelSEED.log",
				"log4perl.appender.LOGFILE.mode=append",
				"",
				"log4perl.appender.LOGFILE.layout=PatternLayout",
				"log4perl.appender.LOGFILE.layout.ConversionPattern=[%r] %F %L %c - %m%n",
	    	]);
	    }
    	Log::Log4perl::init(Bio::KBase::ObjectAPI::config::config_directory()."ProbModelSEED.conf");
    	$logger = Log::Log4perl->get_logger("ProbModelSEEDHelper");
    }
    return $logger;
}

sub log {
    my $msg = shift;
    my $type = shift;
    if (!defined($type)) {
    	$type = "info";
    }
    Bio::KBase::ObjectAPI::logging::logger()->$type('<msg type="'.$type.'" time="'.DateTime->now()->datetime().'" pid="'.$processid.'" user="'.Bio::KBase::ObjectAPI::config::username().'">'."\n".$msg."\n</msg>\n");
}

1;
