package Bio::KBase::ObjectAPI::utilities;
use strict;
use warnings;
use Carp qw(cluck);
use Data::Dumper;
use File::Temp qw(tempfile);
use File::Path;
use File::Copy::Recursive;
use JSON::XS;
use HTTP::Request::Common;

our $VERBOSE = undef; # A GLOBAL Reference to print verbose() calls to, or undef.
our $CONFIG = undef;
our $keggmaphash = undef;
our $report = {};
our $source = undef;
our $defbio = undef;
our $globalparams = {"gapfill name" => "none"};
our $startime = undef;
our $classifierdata = undef;
our $full_trace = 1;

=head1 Bio::KBase::ObjectAPI::utilities

Basic utility functions in the ModelSEED

=head2 Argument Processing

=head3 args

    $args = args( $required, $optional, ... );

Process arguments for a given function. C<required> is an ArrayRef
of strings that correspond to required arguments for the function.
C<optional> is a HashRef that defines arguments with default values.
The remaining values are the arguments to the function. E.g.

    sub function {
        my $self = shift;
        my $args = args ( [ "name" ], { phone => "867-5309" }, @_ );
        return $args;
    }
    # The following calls will work
    print Dumper function(name => "bob", phone => "555-555-5555");
    # Prints { name => "bob", phone => "555-555-5555" }
    print Dumper function( { name => "bob" } );
    # Prints { name => "bob", phone => "867-5309" }
    print Dumper function();
    # dies, name must be defined...

=head2 Warnings

=head3 error

    error("String");

Confesses an error to stderr.

=head2 Printing Verbosely

There are two functions in this package that control the printing of verbose
messages: C<verbose> and C<set_verbose>.

=head3 verbose

    $rtv = verbose("string one", "string two");

Call with a list of strings to print a message if the verbose flag has been
set. If the list of strings is empty, nothing is printed. Returns true if
the verbose flag is set. Otherwise returns undef.

=head3 set_verbose

    $rtv = set_verbose($arg);

Calling with a GLOB reference sets the filehandle that C<verbose()>
prints to that reference and sets the verbose flag. Calling with
the value 1 sets the verbose flag and causes C<verbose()> to print
to C<STDERR>.  Calling with any other unsets the verbose flag.
Returns the GLOB Reference that C<verbose()> will print to if the
verbose flag is set. Otherwise it returns undef.

=cut

sub set_verbose {
    my $val = shift;
    if(defined $val && ref $val eq 'GLOB') {
        $VERBOSE = $val;
    } elsif(defined $val && $val eq 1) {
        $VERBOSE = \*STDERR;
    } else {
        $VERBOSE = undef;
    }
    return $VERBOSE;
}

sub verbose {
    if ( defined $VERBOSE ) {
        print $VERBOSE join("\n",@_)."\n" if @_;
        return 1;
    } else {
        return 0;
    }
}

=head3 report

Definition:
	report(string topic,string message);
Description:
	Record a message in the analysis report on the specified topic

=cut
sub report {
	my ($topic,$message) = @_;
	push(@{$report->{$topic}},$message);
};

=head3 get_new_id

Definition:
	string id = get_new_id(string prefix);
Description:
	Returns ID with given prefix

=cut
sub get_new_id {
	my ($prefix) = @_;
	my $id = idServer()->allocate_id_range( $prefix, 1 );
    $id = $prefix.$id;
	return $id;
};

sub _get_args {
    my $args;
    if (ref $_[0] eq 'HASH') {
        $args = $_[0];
    } elsif(scalar(@_) % 2 == 0) {
        my %hash = @_;
        $args = \%hash;
    } elsif(@_) {
        my ($package, $filename, $line, $sub) = caller(1);
        error("Final argument to $package\:\:$sub must be a ".
              "HashRef or an Array of even length");
    } else {
        $args = {};
    }
    return $args;
}

sub usage {
    my $mandatory = shift;
    my $optional  = shift;
    my $args = _get_args(@_);
    return USAGE($mandatory, $optional, $args);
}

sub args {
    my $mandatory = shift;
    my $optional  = shift;
    my $args      = _get_args(@_);
    my @errors;
    foreach my $arg (@$mandatory) {
        push(@errors, $arg) unless defined($args->{$arg});
    }
    if (@errors) {
        my $usage = usage($mandatory, $optional, $args);
        my $missing = join("; ", @errors);
        error("Mandatory arguments $missing missing. Usage: $usage");
    }
    foreach my $arg (keys %$optional) {
	#unusual cases of empty strings/arrays not being assigned default argument
	#these arise if input data simply has empty fields
	#can't use the '!' operator normally because an actual zero is correct
	if( ((ref($args->{$arg}) eq "" || ref($args->{$arg}) eq "SCALAR") && (!defined($args->{$arg}) ||  $args->{$arg} eq "")) ||
	    (ref($args->{$arg}) eq "ARRAY" && scalar(@{$args->{$arg}})==1 && (!defined($args->{$arg}->[0]) || $args->{$arg}->[0] eq ""))){
	    delete $args->{$arg};
	}

        $args->{$arg} = $optional->{$arg} unless defined $args->{$arg};
    }
    return $args;
}

=head3 ARGS

Definition:
	ARGS->({}:arguments,[string]:mandatory arguments,{}:optional arguments);
Description:
	Processes arguments to authenticate users and perform other needed tasks

=cut

sub ARGS {
	my ($args,$mandatoryArguments,$optionalArguments,$substitutions) = @_;
	if (!defined($args)) {
	    $args = {};
	}
	if (ref($args) ne "HASH") {
		Bio::KBase::ObjectAPI::utilities::error("Arguments not hash");	
	}
	if (defined($substitutions) && ref($substitutions) eq "HASH") {
		foreach my $original (keys(%{$substitutions})) {
			$args->{$original} = $args->{$substitutions->{$original}};
		}
	}
	if (defined($mandatoryArguments)) {
		for (my $i=0; $i < @{$mandatoryArguments}; $i++) {
			if (!defined($args->{$mandatoryArguments->[$i]})) {
				push(@{$args->{_error}},$mandatoryArguments->[$i]);
			}
		}
	}
	Bio::KBase::ObjectAPI::utilities::error("Mandatory arguments ".join("; ",@{$args->{_error}})." missing. Usage:".Bio::KBase::ObjectAPI::utilities::USAGE($mandatoryArguments,$optionalArguments,$args)) if (defined($args->{_error}));
	if (defined($optionalArguments)) {
		foreach my $argument (keys(%{$optionalArguments})) {
			if (!defined($args->{$argument})) {
				$args->{$argument} = $optionalArguments->{$argument};
			}
		}	
	}
	return $args;
}

=head3 USAGE

Definition:
	string = Bio::KBase::ObjectAPI::utilities::USAGE([]:madatory arguments,{}:optional arguments);
Description:
	Prints the usage for the current function call.

=cut

sub USAGE {
	my ($mandatoryArguments,$optionalArguments,$args) = @_;
	my $current = 1;
	my @calldata = caller($current);
	while ($calldata[3] eq "Bio::KBase::ObjectAPI::utilities::ARGS") {
		$current++;
		@calldata = caller($current);
	}
	my $call = $calldata[3];
	my $usage = "";
	if (defined($mandatoryArguments)) {
		for (my $i=0; $i < @{$mandatoryArguments}; $i++) {
			if (length($usage) > 0) {
				$usage .= "/";	
			}
			$usage .= $mandatoryArguments->[$i];
			if (defined($args)) {
				$usage .= " => ";
				if (defined($args->{$mandatoryArguments->[$i]})) {
					$usage .= $args->{$mandatoryArguments->[$i]};
				} else {
					$usage .= " => ?";
				}
			}
		}
	}
	if (defined($optionalArguments)) {
		my $optArgs = [keys(%{$optionalArguments})];
		for (my $i=0; $i < @{$optArgs}; $i++) {
			if (length($usage) > 0) {
				$usage .= "/";	
			}
			$usage .= $optArgs->[$i]."(".$optionalArguments->{$optArgs->[$i]}.")";
			if (defined($args)) {
				$usage .= " => ";
				if (defined($args->{$optArgs->[$i]})) {
					$usage .= $args->{$optArgs->[$i]};
				} else {
					$usage .= " => ".$optionalArguments->{$optArgs->[$i]};
				}
			}
		}
	}
	return $call."{".$usage."}";
}

=head3 error

Definition:
	void Bio::KBase::ObjectAPI::utilities::error();
Description:	

=cut

sub error {	
	my ($message) = @_;
    if ($full_trace == 1) {
		Carp::confess($message);
    } else {
    	die $message;
    }
}

=head3 USEERROR

Definition:
	void Bio::KBase::ObjectAPI::utilities::USEERROR();
Description:	

=cut

sub USEERROR {	
	my ($message) = @_;
	print STDERR "\n".$message."\n\n";
	exit();
}

=head3 USEWARNING

Definition:
	void Bio::KBase::ObjectAPI::utilities::USEWARNING();
Description:	

=cut

sub USEWARNING {	
	my ($message) = @_;
	print STDERR "\n".$message."\n\n";
}

=head3 PRINTFILE
Definition:
	void Bio::KBase::ObjectAPI::utilities::PRINTFILE();
Description:	

=cut

sub PRINTFILE {
    my ($filename,$arrayRef) = @_;
    open ( my $fh, ">", $filename) || Bio::KBase::ObjectAPI::utilities::error("Failure to open file: $filename, $!");
    foreach my $Item (@{$arrayRef}) {
    	print $fh $Item."\n";
    }
    close($fh);
}

=head3 TOJSON

Definition:
	void Bio::KBase::ObjectAPI::utilities::TOJSON(REF);
Description:	

=cut

sub TOJSON {
    my ($ref,$prettyprint) = @_;
    my $JSON = JSON->new->utf8(1);
    if (defined($prettyprint) && $prettyprint == 1) {
		$JSON->pretty(1);
    }
    return $JSON->encode($ref);
}

=head3 FROMJSON

Definition:
	REF Bio::KBase::ObjectAPI::utilities::FROMJSON(string);
Description:	

=cut

sub FROMJSON {
    my ($data) = @_;
    if (!defined($data)) {
    	Bio::KBase::ObjectAPI::utilities::error("Data undefined!");
    }
    return decode_json $data;
}

=head3 LOADFILE
Definition:
	void Bio::KBase::ObjectAPI::utilities::LOADFILE();
Description:	

=cut

sub LOADFILE {
    my ($filename) = @_;
    my $DataArrayRef = [];
    open (my $fh, "<", $filename) || Bio::KBase::ObjectAPI::utilities::error("Couldn't open $filename: $!");
    while (my $Line = <$fh>) {
        $Line =~ s/\r//;
        chomp($Line);
        push(@{$DataArrayRef},$Line);
    }
    close($fh);
    return $DataArrayRef;
}

=head3 LOADTABLE
Definition:
	void Bio::KBase::ObjectAPI::utilities::LOADTABLE(string:filename,string:delimiter);
Description:	

=cut

sub LOADTABLE {
    my ($filename,$delim,$headingLine) = @_;
    if (!defined($headingLine)) {
    	$headingLine = 0;
    }
    my $output = {
    	headings => [],
    	data => []
    };
    if ($delim eq "|") {
    	$delim = "\\|";	
    }
    if ($delim eq "\t") {
    	$delim = "\\t";	
    }
    my $data = Bio::KBase::ObjectAPI::utilities::LOADFILE($filename);
    if (defined($data->[0])) {
    	$output->{headings} = [split(/$delim/,$data->[$headingLine])];
	    for (my $i=($headingLine+1); $i < @{$data}; $i++) {
	    	push(@{$output->{data}},[split(/$delim/,$data->[$i])]);
	    }
    }
    return $output;
}

=head3 PRINTTABLE

Definition:
	void Bio::KBase::ObjectAPI::utilities::PRINTTABLE(string:filename,{}:table);
Description:

=cut

sub PRINTTABLE {
    my ($filename,$table,$delimiter) = @_;
    if (!defined($delimiter)) {
    	$delimiter = "\t";
    } 
    my $out_fh;
    if ($filename eq "STDOUT") {
    	$out_fh = \*STDOUT;
    } else {
    	open ( $out_fh, ">", $filename) || Bio::KBase::ObjectAPI::utilities::USEERROR("Failure to open file: $filename, $!");
    }
	print $out_fh join($delimiter,@{$table->{headings}})."\n";
	foreach my $row (@{$table->{data}}) {
		print $out_fh join($delimiter,@{$row})."\n";
	}
    if ($filename ne "STDOUT") {
    	close ($out_fh);
    }
}

=head3 PRINTTABLESPARSE

Definition:
	void Bio::KBase::ObjectAPI::utilities::PRINTTABLESPARSE(string:filename,table:table,string:delimiter,double:min,double:max);
Description:	

=cut

sub PRINTTABLESPARSE {
    my ($filename,$table,$delimiter,$min,$max) = @_;
    if (!defined($delimiter)) {
    	$delimiter = "\t";
    } 
    my $out_fh;
    if ($filename eq "STDOUT") {
    	$out_fh = \*STDOUT;
    } else {
    	open ( $out_fh, ">", $filename) || Bio::KBase::ObjectAPI::utilities::USEERROR("Failure to open file: $filename, $!");
    }
    for (my $i=1; $i < @{$table->{data}};$i++) {
    	for (my $j=1; $j < @{$table->{headings}};$j++) {
    		if (defined($table->{data}->[$i]->[$j])) {
    			if (!defined($min) || $table->{data}->[$i]->[$j] >= $min) {
    				if (!defined($max) || $table->{data}->[$i]->[$j] <= $max) {
    					print $out_fh $table->{data}->[$i]->[0].$delimiter.$table->{headings}->[$j].$delimiter.$table->{data}->[$i]->[$j]."\n";
    				}
    			}
    		}	
    	}
    }
    if ($filename ne "STDOUT") {
    	close ($out_fh);
    }
}

=head3 PRINTHTMLTABLE

Definition:
    string = Bio::KBase::ObjectAPI::utilities::PRINTHTMLTABLE( array[string]:headers, array[array[string]]:data, string:table_class );
Description:
    Utility method to print html table
Example:
    my $headers = ['Column 1', 'Column 2', 'Column 3'];
    my $data = [['1.1', '1.2', '1.3'], ['2.1', '2.2', '2.3'], ['3.1', '3.2', '3.3']];
    my $html = Bio::KBase::ObjectAPI::utilities::PRINTHTMLTABLE( $headers, $data, 'my-class');

=cut

sub PRINTHTMLTABLE {
    my ($headers, $data, $class) = @_;

    # do some checking
    my $error = 0;
    unless (defined($headers) && ref($headers) eq 'ARRAY') {
        $error = 1;
    }

    if (defined($data) && ref($data) eq 'ARRAY') {
        foreach my $row (@$data) {
            unless (defined($row) && ref($row) eq 'ARRAY' && scalar @$row == scalar @$headers) {
                $error = 1;
            }
        }
    } else {
        $error = 1;
    }

    if ($error) {
        error("Call to PRINTHTMLTABLE failed: incorrect arguments and/or argument structure");
    }

    # now create the table
    my $html = [];
    push(@$html, '<table' . (defined($class) ? ' class="' . $class . '"' : "") . ">");
    push(@$html, '<thead>');
    push(@$html, '<tr>');

    foreach my $header (@$headers) {
        push(@$html, '<th>' . $header . '</th>');
    }

    push(@$html, '</tr>');
    push(@$html, '</thead>');
    push(@$html, '<tbody>');

    foreach my $row (@$data) {
        push(@$html, '<tr>');
        foreach my $cell (@$row) {
            push(@$html, '<td>' . $cell . '</td>');
        }
        push(@$html, '</tr>');
    }

    push(@$html, '</tbody>');
    push(@$html, '</table>');

    return join("\n", @$html);
}

=head3 CLASSIFIER_BINARY

Definition:
	string = Bio::KBase::ObjectAPI::utilities::CLASSIFIER_BINARY(string input);
Description:
	Getter setter for where the classifier binary is located
Example:

=cut

sub CLASSIFIER_PATH {
	my ($input) = @_;
	if (defined($input)) {
		$ENV{CLASSIFIER_PATH} = $input;
	}
	return $ENV{CLASSIFIER_PATH};
}

=head3 CurrentJobID

Definition:
	string = Bio::KBase::ObjectAPI::utilities::CurrentJobID(string input);
Description:
	Getter setter for the current job id to be used as directory name for MFAToolkit jobs
Example:

=cut

sub CurrentJobID {
	my ($input) = @_;
	if (defined($input)) {
		$ENV{KBFBA_CurrentJobID} = $input;
	}
	return $ENV{KBFBA_CurrentJobID};
}

=head3 source

Definition:
	string = Bio::KBase::ObjectAPI::utilities::source(string input);
Description:
	Getter setter for the source reported for reconstructed models
Example:

=cut

sub source {
	my ($input) = @_;
	if (defined($input)) {
		$source = $input;
	}
	return $source;
}

sub default_biochemistry {
	my ($input) = @_;
	if (defined($input)) {
		$defbio = $input;
	}
	return $defbio;
}

=head3 parseArrayString

Definition:
	string = Bio::KBase::ObjectAPI::utilities::parseArrayString({
		string => string(none),
		delimiter => string(|),
		array => [](undef)	
	});
Description:
	Parses string into array
Example:

=cut

sub parseArrayString {
	my ($args) = @_;
	$args = Bio::KBase::ObjectAPI::utilities::ARGS($args,[],{
		string => "none",
		delimiter => "|",
	});
	if ($args->{delimiter} eq "|") {
		$args->{delimiter} = "\\|";
	}
	my $output = [];
	my $delim = $args->{delimiter};
	if ($args->{string} ne "none") {
		$output = [split(/$delim/,$args->{string})];
	}
	return $output;
}

=head3 translateArrayOptions

Definition:
	string = Bio::KBase::ObjectAPI::utilities::translateArrayOptions({
		option => string|[],
		delimiter => string:|
	});
Description:
	Parses argument options into array
Example:

=cut

sub translateArrayOptions {
	my ($args) = @_;
	$args = Bio::KBase::ObjectAPI::utilities::ARGS($args,["option"],{
		delimiter => "|"
	});
	if ($args->{delimiter} eq "|") {
		$args->{delimiter} = "\\|";
	}
	if ($args->{delimiter} eq ";") {
		$args->{delimiter} = "\\;";
	}
	my $output = [];
	if (ref($args->{option}) eq "ARRAY") {
		foreach my $item (@{$args->{option}}) {
			push(@{$output},split($args->{delimiter},$item));
		}
	} else {
		$output = [split($args->{delimiter},$args->{option})];
	}
	return $output;
}

=head3 convertRoleToSearchRole
Definition:
	string:searchrole = Bio::KBase::ObjectAPI::Utilities::convertRoleToSearchRole->(string rolename);
Description:
	Converts the input role name into a search name by removing spaces, capitalization, EC numbers, and some punctuation.

=cut

sub convertRoleToSearchRole {
	my ($rolename) = @_;
	$rolename = lc($rolename);
	$rolename =~ s/[\d\-]+\.[\d\-]+\.[\d\-]+\.[\d\-]+//g;
	$rolename =~ s/\s//g;
	$rolename =~ s/\#.*$//g;
	$rolename =~ s/\(ec\)//g;
	return $rolename;
}

=head3 parseGPR

Definition:
	{}:Logic hash = ModelSEED::MS::Factories::SBMLFactory->parseGPR();
Description:
	Parses GPR string into a hash where each key is a node ID,
	and each node ID points to a logical expression of genes or other
	node IDs. 
	
	Logical expressions only have one form of logic, either "or" or "and".

	Every hash returned has a root node called "root", and this is
	where the gene protein reaction boolean rule starts.
Example:
	GPR string "(A and B) or (C and D)" is translated into:
	{
		root => "node1|node2",
		node1 => "A+B",
		node2 => "C+D"
	}
	
=cut

sub parseGPR {
	my $gpr = shift;
	$gpr =~ s/\|/___/g;
	$gpr =~ s/\s+and\s+/;/ig;
	$gpr =~ s/\s+or\s+/:/ig;
	$gpr =~ s/\s+\)/)/g;
	$gpr =~ s/\)\s+/)/g;
	$gpr =~ s/\s+\(/(/g;
	$gpr =~ s/\(\s+/(/g;
	my $index = 1;
	my $gprHash = {_baseGPR => $gpr};
	while ($gpr =~ m/\(([^\)^\(]+)\)/) {
		my $node = $1;
		my $text = "\\(".$node."\\)";
		if ($node !~ m/;/ && $node !~ m/:/) {
			$gpr =~ s/$text/$node/g;
		} else {
			my $nodeid = "node".$index;
			$index++;
			$gpr =~ s/$text/$nodeid/g;
			$gprHash->{$nodeid} = $node;
		}
	}
	$gprHash->{root} = $gpr;
	$index = 0;
	my $nodelist = ["root"];
	while (defined($nodelist->[$index])) {
		my $currentNode = $nodelist->[$index];
		my $data = $gprHash->{$currentNode};
		my $delim = "";
		if ($data =~ m/;/) {
			$delim = ";";
		} elsif ($data =~ m/:/) {
			$delim = ":";
		}
		if (length($delim) > 0) {
			my $split = [split(/$delim/,$data)];
			foreach my $item (@{$split}) {
				if (defined($gprHash->{$item})) {
					my $newdata = $gprHash->{$item};
					if ($newdata =~ m/$delim/) {
						$gprHash->{$currentNode} =~ s/$item/$newdata/g;
						delete $gprHash->{$item};
						$index--;
					} else {
						push(@{$nodelist},$item);
					}
				}
			}
		} elsif (defined($gprHash->{$data})) {
			push(@{$nodelist},$data);
		}
		$index++;
	}
	foreach my $item (keys(%{$gprHash})) {
		$gprHash->{$item} =~ s/;/+/g;
		$gprHash->{$item} =~ s/___/\|/g;
	}
	return $gprHash;
}

=head3 _translateGPRHash

Definition:
	[[[]]]:Protein subunit gene array = ModelSEED::MS::Factories::SBMLFactory->translateGPRHash({}:GPR hash);
Description:
	Translates the GPR hash generated by "parseGPR" into a three level array ref.
	The three level array ref represents the three levels of GPR rules in the ModelSEED.
	The outermost array represents proteins (with 'or' logic).
	The next level array represents subunits (with 'and' logic).
	The innermost array represents gene homologs (with 'or' logic).
	In order to be parsed into this form, the input GPR hash must include logic
	of the forms: "or(and(or))" or "or(and)" or "and" or "or"
	
Example:
	GPR hash:
	{
		root => "node1|node2",
		node1 => "A+B",
		node2 => "C+D"
	}
	Is translated into the array:
	[
		[
			["A"],
			["B"]
		],
		[
			["C"],
			["D"]
		]
	]

=cut

sub translateGPRHash {
	my $gprHash = shift;
	my $root = $gprHash->{root};
	my $proteins = [];
	if ($root =~ m/:/) {
		my $proteinItems = [split(/:/,$root)];
		my $found = 0;
		foreach my $item (@{$proteinItems}) {
			if (defined($gprHash->{$item})) {
				$found = 1;
				last;
			}
		}
		if ($found == 0) {
			$proteins->[0]->[0] = $proteinItems
		} else {
			foreach my $item (@{$proteinItems}) {
				push(@{$proteins},Bio::KBase::ObjectAPI::utilities::parseSingleProtein($item,$gprHash));
			}
		}
	} elsif ($root =~ m/\+/) {
		$proteins->[0] = Bio::KBase::ObjectAPI::utilities::parseSingleProtein($root,$gprHash);
	} elsif (defined($gprHash->{$root})) {
		$gprHash->{root} = $gprHash->{$root};
		return Bio::KBase::ObjectAPI::utilities::translateGPRHash($gprHash);
	} else {
		$proteins->[0]->[0]->[0] = $root;
	}
	return $proteins;
}

=head3 parseSingleProtein

Definition:
	[[]]:Subunit gene array = ModelSEED::MS::Factories::SBMLFactory->parseSingleProtein({}:GPR hash);
Description:
	Translates the GPR hash generated by "parseGPR" into a two level array ref.
	The two level array ref represents the two levels of GPR rules in the ModelSEED.
	The outermost array represents subunits (with 'and' logic).
	The innermost array represents gene homologs (with 'or' logic).
	In order to be parsed into this form, the input GPR hash must include logic
	of the forms: "and(or)" or "and" or "or"
	
Example:
	GPR hash:
	{
		root => "A+B",
	}
	Is translated into the array:
	[
		["A"],
		["B"]
	]

=cut

sub parseSingleProtein {
	my $node = shift;
	my $gprHash = shift;
	my $subunits = [];
	if ($node =~ m/\+/) {
		my $items = [split(/\+/,$node)];
		my $index = 0;
		foreach my $item (@{$items}) {
			if (defined($gprHash->{$item})) {
				my $subunitNode = $gprHash->{$item};
				if ($subunitNode =~ m/:/) {
					my $suitems = [split(/:/,$subunitNode)];
					my $found = 0;
					foreach my $suitem (@{$suitems}) {
						if (defined($gprHash->{$suitem})) {
							$found = 1;
						}
					}
					if ($found == 0) {
						$subunits->[$index] = $suitems;
						$index++;
					} else {
						print "Incompatible GPR:".$gprHash->{_baseGPR}."\n";
					}
				} elsif ($subunitNode =~ m/\+/) {
					print "Incompatible GPR:".$gprHash->{_baseGPR}."\n";
				} else {
					$subunits->[$index]->[0] = $subunitNode;
					$index++;
				}
			} else {
				$subunits->[$index]->[0] = $item;
				$index++;
			}
		}
	} elsif (defined($gprHash->{$node})) {
		return Bio::KBase::ObjectAPI::utilities::parseSingleProtein($gprHash->{$node},$gprHash)
	} else {
		$subunits->[0]->[0] = $node;
	}
	return $subunits;
}

sub KEGGMapHash {
	if (!defined($keggmaphash)) {
		my $rxns = [qw(rxn00221 rxn00459 rxn00536 rxn00543 rxn00544 rxn00779 rxn01104 rxn01106 rxn01169 rxn01171 rxn01216 rxn02380 rxn03481 rxn03482 rxn03517 rxn06118 rxn06120 rxn06231 rxn06678 rxn06860 rxn07191 rxn00199 rxn00265 rxn00441 rxn00505 rxn00520 rxn01387 rxn01872 rxn02376 rxn06109 rxn00772 rxn00784 rxn01107 rxn01108 rxn01109 rxn01110 rxn01121 rxn01126 rxn01275 rxn01277 rxn01279 rxn01333 rxn01474 rxn01476 rxn01477 rxn01921 rxn01986 rxn01987 rxn04651 rxn04652 rxn05806 rxn07122 rxn01176 rxn03932 rxn12146 rxn12147 rxn01041 rxn01043 rxn01044 rxn01080 rxn01112 rxn01113 rxn01114 rxn01122 rxn01124 rxn01199 rxn01290 rxn01291 rxn01292 rxn01306 rxn01308 rxn01382 rxn01383 rxn01385 rxn01386 rxn01389 rxn01390 rxn01391 rxn01392 rxn01393 rxn01394 rxn01457 rxn01751 rxn01753 rxn01763 rxn01764 rxn01775 rxn01857 rxn01913 rxn02089 rxn03042 rxn03043 rxn03643 rxn03883 rxn03885 rxn04064 rxn05122 rxn06156 rxn00223 rxn00546 rxn00550 rxn00551 rxn00559 rxn00626 rxn00627 rxn00629 rxn00630 rxn00632 rxn00634 rxn00636 rxn00638 rxn00639 rxn00640 rxn00641 rxn00642 rxn00780 rxn00975 rxn01310 rxn01329 rxn01431 rxn01492 rxn01560 rxn01619 rxn01620 rxn01621 rxn01761 rxn01762 rxn01870 rxn01936 rxn01969 rxn01971 rxn02092 rxn02161 rxn02210 rxn02262 rxn02263 rxn02313 rxn02319 rxn02437 rxn02438 rxn02439 rxn02440 rxn02608 rxn02675 rxn02676 rxn02770 rxn03886 rxn03962 rxn04021 rxn04037 rxn05906 rxn05907 rxn05973 rxn06201 rxn06224 rxn06318 rxn06348 rxn06578 rxn06983 rxn11993 rxn00356 rxn00783 rxn00787 rxn00808 rxn00810 rxn00813 rxn00814 rxn00816 rxn00817 rxn00818 rxn00819 rxn00888 rxn00890 rxn00977 rxn01737 rxn01738 rxn02093 rxn02094 rxn02095 rxn02173 rxn02174 rxn02314 rxn02315 rxn02316 rxn02317 rxn02318 rxn02332 rxn02429 rxn02451 rxn02596 rxn02597 rxn03504 rxn03838 rxn03856 rxn05852 rxn05929 rxn06677 rxn06934 rxn11551 rxn11552 rxn11877 rxn11878 rxn11879 rxn00028 rxn00071 rxn00196 rxn00443 rxn00445 rxn00447 rxn00448 rxn00449 rxn00643 rxn01081 rxn01289 rxn01633 rxn01634 rxn01828 rxn01830 rxn01989 rxn01990 rxn02100 rxn02122 rxn02278 rxn02279 rxn02280 rxn02346 rxn02651 rxn03275 rxn03887 rxn06337 rxn07486 rxn07487 rxn07488 rxn07489 rxn07490 rxn07491 rxn07492 rxn07493 rxn07494 rxn07495 rxn07845 rxn11554 rxn11600 rxn05322 rxn05323 rxn05324 rxn05325 rxn05326 rxn05327 rxn05328 rxn05329 rxn05330 rxn05331 rxn05332 rxn05333 rxn05334 rxn05335 rxn05336 rxn05337 rxn05338 rxn05339 rxn05340 rxn05341 rxn05342 rxn05343 rxn05344 rxn05345 rxn05346 rxn05347 rxn05348 rxn05349 rxn05350 rxn05351 rxn05352 rxn05353 rxn05354 rxn05355 rxn05356 rxn05357 rxn05465 rxn06033 rxn06251 rxn06556 rxn06672 rxn06673 rxn08433 rxn08434 rxn08438 rxn11699 rxn11700 rxn12017 rxn00945 rxn02678 rxn02719 rxn02802 rxn03252 rxn04793 rxn00872 rxn00946 rxn00947 rxn01247 rxn01409 rxn01781 rxn01802 rxn02679 rxn02720 rxn02803 rxn03251 rxn03253 rxn03254 rxn05853 rxn05857 rxn05871 rxn05884 rxn05985 rxn05986 rxn05996 rxn06071 rxn06072 rxn06148 rxn06596 rxn00498 rxn00829 rxn01058 rxn01062 rxn01063 rxn01487 rxn01501 rxn01607 rxn02062 rxn02063 rxn02290 rxn02291 rxn02322 rxn02371 rxn02407 rxn02578 rxn02618 rxn02677 rxn03007 rxn03063 rxn03891 rxn03892 rxn03907 rxn03908 rxn03909 rxn03910 rxn03911 rxn03912 rxn03913 rxn03958 rxn03973 rxn03996 rxn04028 rxn04113 rxn04993 rxn05004 rxn05028 rxn06424 rxn06429 rxn06431 rxn06464 rxn06762 rxn06991 rxn07312 rxn07313 rxn07314 rxn07315 rxn07316 rxn07317 rxn07318 rxn07319 rxn07320 rxn07321 rxn07322 rxn07323 rxn07324 rxn07325 rxn07326 rxn07327 rxn07328 rxn07331 rxn07332 rxn07333 rxn07334 rxn07335 rxn07336 rxn07337 rxn11681 rxn11682 rxn11683 rxn11990 rxn12005 rxn12008 rxn01064 rxn01066 rxn01067 rxn02014 rxn02015 rxn02016 rxn02505 rxn02506 rxn02638 rxn02639 rxn02794 rxn02795 rxn02796 rxn02797 rxn02973 rxn03094 rxn03095 rxn03106 rxn03107 rxn03128 rxn03129 rxn03145 rxn03148 rxn03282 rxn03283 rxn03284 rxn03286 rxn03287 rxn03288 rxn03289 rxn03290 rxn03291 rxn03292 rxn03293 rxn03294 rxn03295 rxn03296 rxn03297 rxn03298 rxn04068 rxn04069 rxn06002 rxn06221 rxn06795 rxn00966 rxn02831 rxn02832 rxn03224 rxn03390 rxn03391 rxn03392 rxn03393 rxn03394 rxn03395 rxn03396 rxn03397 rxn03754 rxn03755 rxn03893 rxn03894 rxn04139 rxn04673 rxn04674 rxn04679 rxn04680 rxn05023 rxn05024 rxn06113 rxn06831 rxn06942 rxn06943 rxn11702 rxn11703 rxn01582 rxn01583 rxn01584 rxn01586 rxn01587 rxn01588 rxn02034 rxn02035 rxn02038 rxn02039 rxn02040 rxn02070 rxn02383 rxn02384 rxn02385 rxn02386 rxn02636 rxn02717 rxn02718 rxn02905 rxn02906 rxn03196 rxn03299 rxn03300 rxn03301 rxn03302 rxn03303 rxn03304 rxn03305 rxn03306 rxn03307 rxn03308 rxn03309 rxn03310 rxn03311 rxn03312 rxn03313 rxn03314 rxn03315 rxn03316 rxn03317 rxn03319 rxn03320 rxn06128 rxn06130 rxn06131 rxn06132 rxn06133 rxn06261 rxn06262 rxn06351 rxn06361 rxn06463 rxn06482 rxn06483 rxn06505 rxn06506 rxn06507 rxn06796 rxn06797 rxn11557 rxn11562 rxn11583 rxn11614 rxn11627 rxn11628 rxn11980 rxn11982 rxn12002 rxn00385 rxn00386 rxn00387 rxn01336 rxn01337 rxn01338 rxn01339 rxn01341 rxn01342 rxn01688 rxn01689 rxn01692 rxn01693 rxn01694 rxn01695 rxn01696 rxn01697 rxn01793 rxn01794 rxn01795 rxn01809 rxn01810 rxn01812 rxn02214 rxn02215 rxn02216 rxn02217 rxn02443 rxn02444 rxn02445 rxn02446 rxn02447 rxn02448 rxn02798 rxn03000 rxn03001 rxn03024 rxn03025 rxn03026 rxn03198 rxn03199 rxn03200 rxn03201 rxn03202 rxn03255 rxn03256 rxn03258 rxn03260 rxn06052 rxn06053 rxn06054 rxn06174 rxn06175 rxn06176 rxn06229 rxn06310 rxn06779 rxn11954 rxn11956 rxn11958 rxn11975 rxn12000 rxn12001 rxn00179 rxn00192 rxn00398 rxn00401 rxn00405 rxn00469 rxn00560 rxn00852 rxn00853 rxn00855 rxn00856 rxn00857 rxn00858 rxn01029 rxn01459 rxn01460 rxn01461 rxn01462 rxn01463 rxn01464 rxn01636 rxn01637 rxn01917 rxn02273 rxn02275 rxn02343 rxn02373 rxn02465 rxn02817 rxn02826 rxn03423 rxn05118 rxn05123 rxn05124 rxn05126 rxn05127 rxn05128 rxn06061 rxn00062 rxn00063 rxn00065 rxn00092 rxn00095 rxn00096 rxn00097 rxn00098 rxn00130 rxn00131 rxn00132 rxn00133 rxn00134 rxn00136 rxn00139 rxn00140 rxn00232 rxn00236 rxn00237 rxn00239 rxn00241 rxn00242 rxn00301 rxn00303 rxn00304 rxn00307 rxn00327 rxn00513 rxn00514 rxn00515 rxn00516 rxn00562 rxn00706 rxn00774 rxn00775 rxn00831 rxn00832 rxn00833 rxn00834 rxn00835 rxn00836 rxn00837 rxn00839 rxn00840 rxn00913 rxn00914 rxn00915 rxn00916 rxn00918 rxn00920 rxn00926 rxn00927 rxn01036 rxn01127 rxn01137 rxn01138 rxn01139 rxn01184 rxn01225 rxn01226 rxn01238 rxn01297 rxn01298 rxn01299 rxn01351 rxn01352 rxn01353 rxn01354 rxn01358 rxn01375 rxn01444 rxn01445 rxn01446 rxn01507 rxn01508 rxn01509 rxn01522 rxn01523 rxn01524 rxn01543 rxn01544 rxn01545 rxn01548 rxn01549 rxn01649 rxn01746 rxn01747 rxn01748 rxn01858 rxn01859 rxn01961 rxn01962 rxn01985 rxn02020 rxn02102 rxn02103 rxn02104 rxn02449 rxn02517 rxn02518 rxn02521 rxn02761 rxn02827 rxn02895 rxn02937 rxn02938 rxn03039 rxn03084 rxn03136 rxn03147 rxn03234 rxn03235 rxn03323 rxn03483 rxn03842 rxn04453 rxn04456 rxn04457 rxn04784 rxn05231 rxn05232 rxn05233 rxn05234 rxn05804 rxn05816 rxn05817 rxn05840 rxn05842 rxn05844 rxn05846 rxn06205 rxn03938 rxn03940 rxn03942 rxn03943 rxn03944 rxn03945 rxn03946 rxn03947 rxn06949 rxn06950 rxn07707 rxn07708 rxn07709 rxn07710 rxn07711 rxn07712 rxn07729 rxn07730 rxn07731 rxn07732 rxn07733 rxn07735 rxn07744 rxn07745 rxn07746 rxn07747 rxn07748 rxn07749 rxn07750 rxn07751 rxn07752 rxn07753 rxn07754 rxn07755 rxn07756 rxn07757 rxn07758 rxn07759 rxn07760 rxn07761 rxn07762 rxn07763 rxn07764 rxn07765 rxn07766 rxn07767 rxn07768 rxn07769 rxn07770 rxn07771 rxn07772 rxn00116 rxn00117 rxn00118 rxn00119 rxn00120 rxn00362 rxn00363 rxn00364 rxn00365 rxn00366 rxn00367 rxn00368 rxn00369 rxn00407 rxn00408 rxn00409 rxn00410 rxn00412 rxn00463 rxn00707 rxn00708 rxn00709 rxn00710 rxn00711 rxn00712 rxn00713 rxn00714 rxn00715 rxn00717 rxn00776 rxn00797 rxn01025 rxn01027 rxn01028 rxn01128 rxn01129 rxn01143 rxn01145 rxn01146 rxn01217 rxn01218 rxn01219 rxn01220 rxn01221 rxn01222 rxn01360 rxn01361 rxn01362 rxn01366 rxn01367 rxn01368 rxn01370 rxn01465 rxn01510 rxn01511 rxn01512 rxn01513 rxn01514 rxn01515 rxn01516 rxn01517 rxn01518 rxn01519 rxn01541 rxn01648 rxn01672 rxn01673 rxn01674 rxn01677 rxn01678 rxn01679 rxn01704 rxn01705 rxn01706 rxn01799 rxn01800 rxn01813 rxn02190 rxn02375 rxn02522 rxn02762 rxn03188 rxn05059 rxn05235 rxn05236 rxn05289 rxn05818 rxn05819 rxn05843 rxn05845 rxn05847 rxn05848 rxn05911 rxn05999 rxn06059 rxn06075 rxn06076 rxn06105 rxn06247 rxn07445 rxn11578 rxn00200 rxn00415 rxn00254 rxn00262 rxn00263 rxn00279 rxn00282 rxn00341 rxn00345 rxn00348 rxn01726 rxn05783 rxn03757 rxn03758 rxn06917 rxn06919 rxn00165 rxn00166 rxn00267 rxn00269 rxn00270 rxn00274 rxn00275 rxn00420 rxn00422 rxn00424 rxn00425 rxn00433 rxn00541 rxn00752 rxn01068 rxn01069 rxn01099 rxn01101 rxn01300 rxn01832 rxn01833 rxn01867 rxn01868 rxn02620 rxn02667 rxn02914 rxn04142 rxn04786 rxn04787 rxn04788 rxn05870 rxn05909 rxn05921 rxn06017 rxn06377 rxn06493 rxn07270 rxn07840 rxn10770 rxn11743 rxn12191 rxn00126 rxn00128 rxn00141 rxn00143 rxn00450 rxn00452 rxn00740 rxn00952 rxn00956 rxn02302 rxn02894 rxn03052 rxn03057 rxn04992 rxn05091 rxn05092 rxn05104 rxn05105 rxn05106 rxn05108 rxn05885 rxn05957 rxn05958 rxn06077 rxn06078 rxn06799 rxn00426 rxn00566 rxn00624 rxn00644 rxn00652 rxn00826 rxn01365 rxn01735 rxn01736 rxn01757 rxn01905 rxn01906 rxn02228 rxn02229 rxn02246 rxn05035 rxn05733 rxn05910 rxn06800 rxn07449 rxn07450 rxn00676 rxn00807 rxn01480 rxn01504 rxn01574 rxn01924 rxn01925 rxn02270 rxn02729 rxn02783 rxn02866 rxn02888 rxn02889 rxn02925 rxn02926 rxn02933 rxn02934 rxn02949 rxn03433 rxn06335 rxn06586 rxn07430 rxn07431 rxn07432 rxn07433 rxn07434 rxn07435 rxn11475 rxn02496 rxn02557 rxn07872 rxn07873 rxn07874 rxn07875 rxn07876 rxn07877 rxn07878 rxn07879 rxn07880 rxn07881 rxn07882 rxn07883 rxn07884 rxn07885 rxn07886 rxn07887 rxn07888 rxn11569 rxn00904 rxn01045 rxn01208 rxn01573 rxn02187 rxn02789 rxn02811 rxn03062 rxn03068 rxn03194 rxn03435 rxn03436 rxn03437 rxn05109 rxn00313 rxn00317 rxn01420 rxn01644 rxn01972 rxn01973 rxn01974 rxn01991 rxn02224 rxn02466 rxn02928 rxn02929 rxn03030 rxn03031 rxn03034 rxn03086 rxn03087 rxn03324 rxn04656 rxn04657 rxn04658 rxn04659 rxn04660 rxn06675 rxn06802 rxn07441 rxn00310 rxn00311 rxn00312 rxn00314 rxn00316 rxn00318 rxn00320 rxn00321 rxn01186 rxn01578 rxn01579 rxn01580 rxn01581 rxn01630 rxn01631 rxn01632 rxn01662 rxn01727 rxn01729 rxn02045 rxn02226 rxn02227 rxn02266 rxn02344 rxn02350 rxn02351 rxn02403 rxn02422 rxn02423 rxn02469 rxn02605 rxn02830 rxn02893 rxn02915 rxn03204 rxn03205 rxn06370 rxn06515 rxn06661 rxn06804 rxn06805 rxn11598 rxn11955 rxn11960 rxn11968 rxn02196 rxn02197 rxn02198 rxn02896 rxn03326 rxn03327 rxn03544 rxn03545 rxn03613 rxn03614 rxn03615 rxn05110 rxn05111 rxn05112 rxn06112 rxn06888 rxn07098 rxn07099 rxn00082 rxn00183 rxn00291 rxn00395 rxn00396 rxn00400 rxn00402 rxn00403 rxn00467 rxn00471 rxn00601 rxn00928 rxn00929 rxn00930 rxn00931 rxn00932 rxn00933 rxn01140 rxn01142 rxn01371 rxn01374 rxn01635 rxn01877 rxn02029 rxn02071 rxn02090 rxn02281 rxn02339 rxn02355 rxn02356 rxn02357 rxn02358 rxn02359 rxn02360 rxn02927 rxn02944 rxn02946 rxn03071 rxn03072 rxn03422 rxn03424 rxn03426 rxn05129 rxn05776 rxn05859 rxn09188 rxn03658 rxn03762 rxn03763 rxn03764 rxn03765 rxn03766 rxn03768 rxn00050 rxn00188 rxn00201 rxn00789 rxn00860 rxn00862 rxn00863 rxn00866 rxn01546 rxn01550 rxn01551 rxn01554 rxn01639 rxn01640 rxn01642 rxn02085 rxn02159 rxn02160 rxn02282 rxn02320 rxn02473 rxn02834 rxn02835 rxn02853 rxn02854 rxn02855 rxn02942 rxn03090 rxn03135 rxn03175 rxn03195 rxn03329 rxn03330 rxn03331 rxn03400 rxn05935 rxn06807 rxn11596 rxn11597 rxn11630 rxn00024 rxn00033 rxn00036 rxn00523 rxn00524 rxn00531 rxn00801 rxn01202 rxn01203 rxn01326 rxn01494 rxn01495 rxn01496 rxn01497 rxn01499 rxn01715 rxn01717 rxn01803 rxn01820 rxn01822 rxn01824 rxn01826 rxn01827 rxn01836 rxn01837 rxn01838 rxn01839 rxn01918 rxn01919 rxn01920 rxn01943 rxn01944 rxn01945 rxn01946 rxn01955 rxn02087 rxn02088 rxn02295 rxn02363 rxn02364 rxn02365 rxn02366 rxn02367 rxn02392 rxn02394 rxn02397 rxn02419 rxn02420 rxn02610 rxn02611 rxn02728 rxn02771 rxn02779 rxn02882 rxn02883 rxn02885 rxn02991 rxn02993 rxn02994 rxn02996 rxn02998 rxn03040 rxn03041 rxn03055 rxn03056 rxn03082 rxn03153 rxn03154 rxn03155 rxn03156 rxn03267 rxn03268 rxn03333 rxn03334 rxn03335 rxn03336 rxn03337 rxn03338 rxn03339 rxn03340 rxn03341 rxn03342 rxn03343 rxn03344 rxn03345 rxn03346 rxn03347 rxn03993 rxn04380 rxn04706 rxn04971 rxn06409 rxn06542 rxn07120 rxn03116 rxn03565 rxn03566 rxn03567 rxn03568 rxn03569 rxn03570 rxn03580 rxn03647 rxn03677 rxn03685 rxn03686 rxn03769 rxn03770 rxn03772 rxn03774 rxn03776 rxn03777 rxn03785 rxn06905 rxn06911 rxn00485 rxn00489 rxn00492 rxn00496 rxn00497 rxn00970 rxn00997 rxn00998 rxn00999 rxn01003 rxn01004 rxn01037 rxn01039 rxn01156 rxn01610 rxn01773 rxn01841 rxn01842 rxn01878 rxn01895 rxn01902 rxn01903 rxn02416 rxn02633 rxn02754 rxn03038 rxn03350 rxn03404 rxn04073 rxn04595 rxn04597 rxn04598 rxn04599 rxn04600 rxn04601 rxn04602 rxn04603 rxn04604 rxn04606 rxn05991 rxn06189 rxn02165 rxn02166 rxn03551 rxn03557 rxn03558 rxn03560 rxn03563 rxn03571 rxn03572 rxn03577 rxn03581 rxn03670 rxn03671 rxn03687 rxn03688 rxn03721 rxn03781 rxn03782 rxn03837 rxn04646 rxn04647 rxn04648 rxn04649 rxn04650 rxn04653 rxn04654 rxn04663 rxn04664 rxn04666 rxn04667 rxn04668 rxn04669 rxn04671 rxn04672 rxn06893 rxn07169 rxn07170 rxn07171 rxn07618 rxn00255 rxn00593 rxn00598 rxn01040 rxn01096 rxn01190 rxn01191 rxn01884 rxn01933 rxn01993 rxn01994 rxn02141 rxn02142 rxn02143 rxn02144 rxn02369 rxn02370 rxn02483 rxn02532 rxn02533 rxn02746 rxn02782 rxn02852 rxn02904 rxn02971 rxn02980 rxn02981 rxn02982 rxn02983 rxn03050 rxn03078 rxn03089 rxn03097 rxn03496 rxn05959 rxn06014 rxn06609 rxn07602 rxn07630 rxn11610 rxn00968 rxn04685 rxn04686 rxn04687 rxn04688 rxn04689 rxn04690 rxn04691 rxn04692 rxn04693 rxn04694 rxn04695 rxn04696 rxn04697 rxn04698 rxn04699 rxn04700 rxn04701 rxn04702 rxn07889 rxn07890 rxn07892 rxn07893 rxn07894 rxn07895 rxn07896 rxn07897 rxn07898 rxn07899 rxn07900 rxn07901 rxn07902 rxn07903 rxn07904 rxn07905 rxn07906 rxn07907 rxn07908 rxn07909 rxn07910 rxn07911 rxn00054 rxn00477 rxn00478 rxn00479 rxn00480 rxn00483 rxn00724 rxn00728 rxn00729 rxn00732 rxn01325 rxn01327 rxn01418 rxn01421 rxn01422 rxn01435 rxn01438 rxn01447 rxn01449 rxn01450 rxn01564 rxn01565 rxn01680 rxn01927 rxn01930 rxn01937 rxn01938 rxn01939 rxn01947 rxn01948 rxn01949 rxn02081 rxn02082 rxn02083 rxn02084 rxn02218 rxn02219 rxn02222 rxn02223 rxn02244 rxn02328 rxn02329 rxn02463 rxn02464 rxn02592 rxn02743 rxn02744 rxn02767 rxn02781 rxn02823 rxn02864 rxn02865 rxn02912 rxn02913 rxn03003 rxn03354 rxn03356 rxn03357 rxn03358 rxn03359 rxn03360 rxn03361 rxn03362 rxn03365 rxn03366 rxn06213 rxn06427 rxn06513 rxn11560 rxn11631 rxn11632 rxn11697 rxn11701 rxn11704 rxn11962 rxn11964 rxn11970 rxn12018 rxn12019 rxn00474 rxn00490 rxn00525 rxn00526 rxn00726 rxn00727 rxn00791 rxn01000 rxn01188 rxn01255 rxn01256 rxn01269 rxn01270 rxn01315 rxn01332 rxn01363 rxn01364 rxn01739 rxn01740 rxn01742 rxn01964 rxn02212 rxn02213 rxn02476 rxn02507 rxn02508 rxn04661 rxn04662 rxn04577 rxn04578 rxn04579 rxn04580 rxn04581 rxn04582 rxn04584 rxn04585 rxn04586 rxn04587 rxn04588 rxn04589 rxn04590 rxn04592 rxn04593 rxn07150 rxn07151 rxn07152 rxn07153 rxn07154 rxn07155 rxn07156 rxn07157 rxn07158 rxn07159 rxn07161 rxn07162 rxn07163 rxn07164 rxn07165 rxn07166 rxn07167 rxn07168 rxn03144 rxn05113 rxn05130 rxn05131 rxn05132 rxn05133 rxn05135 rxn00653 rxn00658 rxn00659 rxn00660 rxn00661 rxn00673 rxn01172 rxn01173 rxn01401 rxn02250 rxn02766 rxn01230 rxn01231 rxn01784 rxn01785 rxn02685 rxn03630 rxn03923 rxn03924 rxn04789 rxn04790 rxn06025 rxn00228 rxn00462 rxn00537 rxn01885 rxn02844 rxn02845 rxn02900 rxn02961 rxn02962 rxn02963 rxn03518 rxn06811 rxn06812 rxn11649 rxn02569 rxn02571 rxn03263 rxn03264 rxn03265 rxn03371 rxn03372 rxn03373 rxn03374 rxn03378 rxn03379 rxn03380 rxn03382 rxn03383 rxn06421 rxn06781 rxn06817 rxn06818 rxn06820 rxn11571 rxn11633 rxn11986 rxn11987 rxn00343 rxn00937 rxn01023 rxn01377 rxn02030 rxn02041 rxn02525 rxn02791 rxn02792 rxn04465 rxn05950 rxn05998 rxn06250 rxn06258 rxn06522 rxn06553 rxn06822 rxn06823 rxn11546 rxn11638 rxn00210 rxn00417 rxn01157 rxn11586 rxn00406 rxn00472 rxn01778 rxn01779 rxn01780 rxn02091 rxn02930 rxn02931 rxn06168 rxn06281 rxn00849 rxn05982 rxn06227 rxn06669 rxn00086 rxn00090 rxn00186 rxn00205 rxn00350 rxn00351 rxn00646 rxn00650 rxn00822 rxn00823 rxn00824 rxn01403 rxn01404 rxn01980 rxn01981 rxn02705 rxn02706 rxn05952 rxn06060 rxn06330 rxn06401 rxn06472 rxn06527 rxn06547 rxn06564 rxn06626 rxn11967 rxn11997 rxn12003 rxn12040 rxn12041 rxn12042 rxn12043 rxn12044 rxn12045 rxn12046 rxn12047 rxn12048 rxn12049 rxn12050 rxn12051 rxn12052 rxn12053 rxn12054 rxn00007 rxn00020 rxn00022 rxn00222 rxn00553 rxn00577 rxn00578 rxn00579 rxn00580 rxn00605 rxn00606 rxn00607 rxn00695 rxn00696 rxn00697 rxn00698 rxn00700 rxn00702 rxn00919 rxn01051 rxn01132 rxn01134 rxn01215 rxn01259 rxn01750 rxn01966 rxn01967 rxn02004 rxn02432 rxn02433 rxn02695 rxn02696 rxn02760 rxn02974 rxn02975 rxn03487 rxn03488 rxn05899 rxn06093 rxn06094 rxn06095 rxn06096 rxn06097 rxn06165 rxn06272 rxn06273 rxn06316 rxn06402 rxn06403 rxn06592 rxn06618 rxn11965 rxn05912 rxn05913 rxn05914 rxn05915 rxn05918 rxn05920 rxn00215 rxn00354 rxn01010 rxn01074 rxn01075 rxn01287 rxn01455 rxn01676 rxn01910 rxn01998 rxn02001 rxn02002 rxn02137 rxn02138 rxn02708 rxn02735 rxn03269 rxn06307 rxn07473 rxn07474 rxn07475 rxn07476 rxn11974 rxn01593 rxn01596 rxn02426 rxn02488 rxn02947 rxn03802 rxn03803 rxn03804 rxn03805 rxn04233 rxn00667 rxn02051 rxn02052 rxn03582 rxn03809 rxn03810 rxn03811 rxn03819 rxn03820 rxn03821 rxn04309 rxn04310 rxn04311 rxn04312 rxn04313 rxn04314 rxn04315 rxn04316 rxn04317 rxn04318 rxn04319 rxn04320 rxn04321 rxn04322 rxn04323 rxn04324 rxn04325 rxn04326 rxn04328 rxn04329 rxn04331 rxn04333 rxn04334 rxn04335 rxn04336 rxn04337 rxn04338 rxn04339 rxn04340 rxn04341 rxn04342 rxn04343 rxn04344 rxn04345 rxn04346 rxn04347 rxn04348 rxn04349 rxn04350 rxn04351 rxn04352 rxn04353 rxn04354 rxn04355 rxn04356 rxn04357 rxn04358 rxn04359 rxn04360 rxn04364 rxn04365 rxn04366 rxn04367 rxn01999 rxn03957 rxn04285 rxn04286 rxn04288 rxn04289 rxn04291 rxn04292 rxn04294 rxn04295 rxn04296 rxn04297 rxn04298 rxn04299 rxn04300 rxn04301 rxn04302 rxn04305 rxn04307 rxn00016 rxn00292 rxn00293 rxn00295 rxn00297 rxn00298 rxn00461 rxn00552 rxn00827 rxn00891 rxn00892 rxn00895 rxn00897 rxn01316 rxn01317 rxn01322 rxn01432 rxn01439 rxn01440 rxn01483 rxn01484 rxn01485 rxn01505 rxn01506 rxn01951 rxn01952 rxn01953 rxn02284 rxn02285 rxn02377 rxn02943 rxn03064 rxn03638 rxn04703 rxn05772 rxn05930 rxn05931 rxn05941 rxn06047 rxn06063 rxn06152 rxn06153 rxn06202 rxn06260 rxn06639 rxn06883 rxn08044 rxn02331 rxn02404 rxn02405 rxn03130 rxn03146 rxn03159 rxn03181 rxn03182 rxn03439 rxn03511 rxn03916 rxn03917 rxn03918 rxn03919 rxn06065 rxn06067 rxn06068 rxn06723 rxn06729 rxn06848 rxn06865 rxn02009 rxn02010 rxn02875 rxn03140 rxn03141 rxn03405 rxn03406 rxn03407 rxn03408 rxn03409 rxn03900 rxn03901 rxn03902 rxn03903 rxn03904 rxn03933 rxn06302 rxn06718 rxn06744 rxn06836 rxn06837 rxn06838 rxn00610 rxn00615 rxn00744 rxn00762 rxn00763 rxn00764 rxn00765 rxn00768 rxn00769 rxn00983 rxn01286 rxn01709 rxn01710 rxn01992 rxn02235 rxn02581 rxn05987 rxn05990 rxn06145 rxn06217 rxn06219 rxn06220 rxn06387 rxn06388 rxn06474 rxn06475 rxn06671 rxn06700 rxn06702 rxn06703 rxn06704 rxn06850 rxn06901 rxn07172 rxn11609 rxn00878 rxn00884 rxn00885 rxn02417 rxn02418 rxn02456 rxn02461 rxn02490 rxn04040 rxn04041 rxn06362 rxn11999 rxn00539 rxn00611 rxn00612 rxn00614 rxn00616 rxn00620 rxn00621 rxn00753 rxn00754 rxn00758 rxn01071 rxn01073 rxn01380 rxn01478 rxn01479 rxn01865 rxn01982 rxn01983 rxn02026 rxn02450 rxn03682 rxn03683 rxn04681 rxn04682 rxn04683 rxn04684 rxn05919 rxn05963 rxn05965 rxn05966 rxn05968 rxn05969 rxn05971 rxn06041 rxn06042 rxn06045 rxn06079 rxn06080 rxn06081 rxn06086 rxn06088 rxn06089 rxn06092 rxn06098 rxn06141 rxn06233 rxn06375 rxn06562 rxn06706 rxn06803 rxn06971 rxn07173 rxn07254 rxn07255 rxn07267 rxn02462 rxn03077 rxn06232 rxn06313 rxn06314 rxn06374 rxn06379 rxn06385 rxn06386 rxn06601 rxn06610 rxn06644 rxn06652 rxn06663 rxn06664 rxn06666 rxn06686 rxn06730 rxn07100 rxn07256 rxn07257 rxn07258 rxn07259 rxn07260 rxn07261 rxn07262 rxn07263 rxn07264 rxn07265 rxn07266 rxn00053 rxn01163 rxn01164 rxn01165 rxn01166 rxn01167 rxn01622 rxn01623 rxn01624 rxn01625 rxn01881 rxn01882 rxn01941 rxn02019 rxn02192 rxn02193 rxn02194 rxn02514 rxn02726 rxn02734 rxn02967 rxn03112 rxn03113 rxn03161 rxn03427 rxn03428 rxn03429 rxn03430 rxn03523 rxn04838 rxn04839 rxn04840 rxn04841 rxn04843 rxn04844 rxn04845 rxn04846 rxn04847 rxn04848 rxn04849 rxn04850 rxn04851 rxn04852 rxn04853 rxn04854 rxn04855 rxn04856 rxn04857 rxn04858 rxn04859 rxn04860 rxn04870 rxn04911 rxn04912 rxn04913 rxn04914 rxn05967 rxn06146 rxn06841 rxn06842 rxn11577 rxn11966 rxn02590 rxn02591 rxn03984 rxn04861 rxn04862 rxn04863 rxn04864 rxn04867 rxn04868 rxn04924 rxn04925 rxn06955 rxn07179 rxn07180 rxn02441 rxn02442 rxn04012 rxn07649 rxn07650 rxn07651 rxn07653 rxn07654 rxn07655 rxn07656 rxn07657 rxn07658 rxn07659 rxn07660 rxn07662 rxn07677 rxn07678 rxn07679 rxn07680 rxn07681 rxn07682 rxn07683 rxn07684 rxn07685 rxn07686 rxn07687 rxn07688 rxn07689 rxn07692 rxn00948 rxn01085 rxn01087 rxn01088 rxn01089 rxn01090 rxn01091 rxn01092 rxn01381 rxn01411 rxn01413 rxn01414 rxn01783 rxn01844 rxn01845 rxn02133 rxn02134 rxn02408 rxn02820 rxn02821 rxn04374 rxn04375 rxn04376 rxn04377 rxn04378 rxn04381 rxn04382 rxn04383 rxn06012 rxn06178 rxn06558 rxn06798 rxn06854 rxn07108 rxn07109 rxn07110 rxn11567 rxn11587 rxn00145 rxn00149 rxn00150 rxn00152 rxn00156 rxn00162 rxn00163 rxn00164 rxn00170 rxn00171 rxn00172 rxn00176 rxn00226 rxn00227 rxn00229 rxn00230 rxn00252 rxn00264 rxn00500 rxn00542 rxn00739 rxn00748 rxn00749 rxn00935 rxn01053 rxn01054 rxn01057 rxn01273 rxn01274 rxn01615 rxn01618 rxn01831 rxn01834 rxn01835 rxn02253 rxn02917 rxn03432 rxn05812 rxn01898 rxn02478 rxn03547 rxn03550 rxn03554 rxn03555 rxn03556 rxn03559 rxn03561 rxn03562 rxn03573 rxn03574 rxn03575 rxn03576 rxn03578 rxn03660 rxn03665 rxn03678 rxn01032 rxn01033 rxn01293 rxn01294 rxn02539 rxn02540 rxn02541 rxn02545 rxn02577 rxn02688 rxn02860 rxn02861 rxn02887 rxn03486 rxn03594 rxn03600 rxn03601 rxn03602 rxn03603 rxn03604 rxn03605 rxn03606 rxn03607 rxn03610 rxn03611 rxn03612 rxn03625 rxn03649 rxn03650 rxn03654 rxn03675 rxn03690 rxn03728 rxn03742 rxn03743 rxn03934 rxn03935 rxn03936 rxn03937 rxn04095 rxn04096 rxn06922 rxn06923 rxn06924 rxn07478 rxn07479 rxn07480 rxn07481 rxn07482 rxn11959 rxn11963 rxn00961 rxn00963 rxn00965 rxn01194 rxn01196 rxn01197 rxn01863 rxn01864 rxn02065 rxn02593 rxn02764 rxn03490 rxn03583 rxn03584 rxn03586 rxn03587 rxn03588 rxn03589 rxn03590 rxn03591 rxn03592 rxn03593 rxn03676 rxn03695 rxn03720 rxn03751 rxn03969 rxn05960 rxn06588 rxn07483 rxn04707 rxn04709 rxn04711 rxn04712 rxn04713 rxn04714 rxn04715 rxn04716 rxn04717 rxn04718 rxn04719 rxn04720 rxn04721 rxn04722 rxn04723 rxn04724 rxn04725 rxn04726 rxn04727 rxn04728 rxn04729 rxn04730 rxn04731 rxn04732 rxn04733 rxn04734 rxn04735 rxn04736 rxn04737 rxn04739 rxn04740 rxn04741 rxn04742 rxn04743 rxn04744 rxn04745 rxn04746 rxn04747 rxn04748 rxn07175 rxn07671 rxn03653 rxn03681 rxn03744 rxn03789 rxn03790 rxn03791 rxn03792 rxn03793 rxn03794 rxn04074 rxn06926 rxn00583 rxn00586 rxn02107 rxn02125 rxn02526 rxn02877 rxn02878 rxn02899 rxn03484 rxn03485 rxn03684 rxn03700 rxn03701 rxn03705 rxn03822 rxn03823 rxn03825 rxn03906 rxn03914 rxn03915 rxn03920 rxn03921 rxn03922 rxn03925 rxn03926 rxn03927 rxn03928 rxn03929 rxn06948 rxn06984 rxn07472 rxn07484 rxn07485 rxn07496 rxn07498 rxn07499 rxn07500 rxn07502 rxn07503 rxn07504 rxn07505 rxn07506 rxn07507 rxn07508 rxn07510 rxn07511 rxn07512 rxn07513 rxn07514 rxn07515 rxn07516 rxn07517 rxn07518 rxn07519 rxn07520 rxn07522 rxn07523 rxn07524 rxn07527 rxn11686 rxn12014 rxn02745 rxn02747 rxn02807 rxn02969 rxn02970 rxn03021 rxn03142 rxn03691 rxn03693 rxn03694 rxn03698 rxn03702 rxn03703 rxn03706 rxn03707 rxn03708 rxn03709 rxn03729 rxn03741 rxn03745 rxn03746 rxn03747 rxn03748 rxn03749 rxn03786 rxn03795 rxn03800 rxn03801 rxn06545 rxn06711 rxn06904 rxn06908 rxn06912 rxn06927 rxn07593 rxn07594 rxn07595 rxn07596 rxn07597 rxn07598 rxn07599 rxn07600 rxn07601 rxn11653 rxn02621 rxn03651 rxn03652 rxn03661 rxn03662 rxn03710 rxn03711 rxn03712 rxn03713 rxn03730 rxn03731 rxn03732 rxn03733 rxn03734 rxn03735 rxn03736 rxn03737 rxn03738 rxn03739 rxn03827 rxn03829 rxn03830 rxn03831 rxn03832 rxn03833 rxn06925 rxn06930 rxn07606 rxn07607 rxn07608 rxn07609 rxn07611 rxn11654 rxn11655 rxn11658 rxn02808 rxn02809 rxn03666 rxn03714 rxn03715 rxn03835 rxn07541 rxn07544 rxn07548 rxn00010 rxn00204 rxn00245 rxn00324 rxn00325 rxn00326 rxn00331 rxn00332 rxn00333 rxn00334 rxn00336 rxn00370 rxn00372 rxn00373 rxn00512 rxn00876 rxn00934 rxn00979 rxn00980 rxn01014 rxn01015 rxn01135 rxn01136 rxn01280 rxn01281 rxn01283 rxn01284 rxn01305 rxn01395 rxn01817 rxn01846 rxn01847 rxn01848 rxn01849 rxn02178 rxn02242 rxn02251 rxn04143 rxn05851 rxn06631 rxn11978 rxn03596 rxn03597 rxn03598 rxn00921 rxn00964 rxn01034 rxn01035 rxn02324 rxn02992 rxn03617 rxn03619 rxn03622 rxn03860 rxn03863 rxn03864 rxn03865 rxn03866 rxn03867 rxn03868 rxn03869 rxn03870 rxn03871 rxn03872 rxn03873 rxn03875 rxn03876 rxn03877 rxn03878 rxn03879 rxn03880 rxn03881 rxn03882 rxn03888 rxn03889 rxn03896 rxn05924 rxn06167 rxn06938 rxn06939 rxn06940 rxn06944 rxn07619 rxn07620 rxn07622 rxn07623 rxn07624 rxn07627 rxn07628 rxn11651 rxn12009 rxn07804 rxn07805 rxn07806 rxn07807 rxn07808 rxn07809 rxn07824 rxn07825 rxn07826 rxn07830 rxn07831 rxn07832 rxn07833 rxn07834 rxn07835 rxn07836 rxn07837 rxn07838 rxn00258 rxn00289 rxn00532 rxn00535 rxn00663 rxn00668 rxn00669 rxn00670 rxn00672 rxn00675 rxn00678 rxn00679 rxn00738 rxn00741 rxn00985 rxn00986 rxn00990 rxn01047 rxn01056 rxn01130 rxn01995 rxn02106 rxn02260 rxn02424 rxn02520 rxn02731 rxn03060 rxn03061 rxn03368 rxn03431 rxn04794 rxn05940 rxn06691 rxn03548 rxn03552 rxn03668 rxn03669 rxn04782 rxn06889 rxn06890 rxn06906 rxn06907 rxn03624 rxn03667 rxn03716 rxn03724 rxn03727 rxn03740 rxn03752 rxn03753 rxn03796 rxn06960 rxn11652 rxn11656 rxn11657 rxn01823 rxn01904 rxn03655 rxn03659 rxn03663 rxn03680 rxn03704 rxn03717 rxn03750 rxn03783 rxn03798 rxn03799 rxn03839 rxn06921 rxn07454 rxn07644 rxn07645 rxn00038 rxn00160 rxn00868 rxn00869 rxn00870 rxn00871 rxn00873 rxn00875 rxn00988 rxn00989 rxn00996 rxn01201 rxn01236 rxn01453 rxn01685 rxn01745 rxn02049 rxn02112 rxn02115 rxn02168 rxn02171 rxn02252 rxn02519 rxn02527 rxn02528 rxn02632 rxn02768 rxn02810 rxn03468 rxn03469 rxn03470 rxn06858 rxn00195 rxn00234 rxn00680 rxn01605 rxn01731 rxn01734 rxn01805 rxn01956 rxn01957 rxn01958 rxn02257 rxn02258 rxn02622 rxn02623 rxn02624 rxn02806 rxn02976 rxn03440 rxn03441 rxn03443 rxn00684 rxn00688 rxn00906 rxn00911 rxn01652 rxn01653 rxn01654 rxn01875 rxn02283 rxn03005 rxn05942 rxn00103 rxn00377 rxn00427 rxn00429 rxn00430 rxn00431 rxn00432 rxn00843 rxn00847 rxn01048 rxn01160 rxn01796 rxn01818 rxn01862 rxn03899 rxn04791 rxn04792 rxn05803 rxn05869 rxn06020 rxn06149 rxn06177 rxn07189 rxn07847 rxn07848 rxn07849 rxn12080 rxn00018 rxn00548 rxn01111 rxn01334 rxn01344 rxn01345 rxn02703 rxn00026 rxn00052 rxn00436 rxn00437 rxn00438 rxn00439 rxn00440 rxn01537 rxn01538 rxn01539 rxn02055 rxn02305 rxn02484 rxn02485 rxn03075 rxn03108 rxn07291 rxn07292 rxn07293 rxn07294 rxn07295 rxn07296 rxn07297 rxn00048 rxn00121 rxn00122 rxn00300 rxn00391 rxn00392 rxn01271 rxn01699 rxn02474 rxn02475 rxn03080 rxn03081 rxn05039 rxn05040 rxn00123 rxn00124 rxn00208 rxn00209 rxn00848 rxn01154 rxn01205 rxn01248 rxn01249 rxn01251 rxn01252 rxn01253 rxn01254 rxn01331 rxn01396 rxn01397 rxn01398 rxn01400 rxn01807 rxn01808 rxn02145 rxn02427 rxn02428 rxn02477 rxn02939 rxn03048 rxn03118 rxn03139 rxn03149 rxn03445 rxn03446 rxn03951 rxn04070 rxn04071 rxn05116 rxn05144 rxn06851 rxn11559 rxn11565 rxn11664 rxn00037 rxn00075 rxn00076 rxn00077 rxn00083 rxn00088 rxn00089 rxn00105 rxn00338 rxn00938 rxn00939 rxn00940 rxn00941 rxn00942 rxn01261 rxn01262 rxn01265 rxn01646 rxn01647 rxn01669 rxn01670 rxn01671 rxn02154 rxn02155 rxn02203 rxn02204 rxn02292 rxn02293 rxn02400 rxn02401 rxn02402 rxn02523 rxn02756 rxn02881 rxn02988 rxn04956 rxn04998 rxn05117 rxn05119 rxn05988 rxn06265 rxn06329 rxn07345 rxn07346 rxn07736 rxn07737 rxn07774 rxn07775 rxn11592 rxn11917 rxn12015 rxn00100 rxn00900 rxn00912 rxn01789 rxn01790 rxn01792 rxn02128 rxn02129 rxn02130 rxn02175 rxn02176 rxn02186 rxn02289 rxn02341 rxn03047 rxn06022 rxn06023 rxn09177 rxn11582 rxn12510 rxn12512 rxn00792 rxn00795 rxn02277 rxn02296 rxn02297 rxn02312 rxn02669 rxn05927 rxn06806 rxn06864 rxn07580 rxn07581 rxn07582 rxn07583 rxn07584 rxn07585 rxn00302 rxn00685 rxn00687 rxn00689 rxn01257 rxn01313 rxn01314 rxn01324 rxn01601 rxn01603 rxn02200 rxn02201 rxn02430 rxn02503 rxn02504 rxn02985 rxn02986 rxn03020 rxn03079 rxn03085 rxn03126 rxn03127 rxn03167 rxn03168 rxn03172 rxn03173 rxn03174 rxn03419 rxn03421 rxn03471 rxn03841 rxn06294 rxn06299 rxn06628 rxn06746 rxn00564 rxn03845 rxn03846 rxn03847 rxn03848 rxn03850 rxn03851 rxn03853 rxn03854 rxn03855 rxn03858 rxn03859 rxn04776 rxn04777 rxn04778 rxn04779 rxn04780 rxn04781 rxn06933 rxn06935 rxn07177 rxn00025 rxn01529 rxn01530 rxn01531 rxn01532 rxn01533 rxn01534 rxn01701 rxn01702 rxn01703 rxn02078 rxn02183 rxn02184 rxn02714 rxn03415 rxn04144 rxn06160 rxn06275 rxn07195 rxn11890 rxn11891 rxn11892 rxn11893 rxn11894 rxn11895 rxn11896 rxn11897 rxn11898 rxn11899 rxn11900 rxn11901 rxn11902 rxn11969 rxn00029 rxn00051 rxn00056 rxn00060 rxn00072 rxn00074 rxn00080 rxn00224 rxn01628 rxn01629 rxn01721 rxn01722 rxn01723 rxn01724 rxn02056 rxn02151 rxn02264 rxn02265 rxn02287 rxn02288 rxn02303 rxn02304 rxn02716 rxn02733 rxn02774 rxn02775 rxn02777 rxn02959 rxn03384 rxn03491 rxn03492 rxn03512 rxn03513 rxn03514 rxn03532 rxn03534 rxn03535 rxn03536 rxn03537 rxn03538 rxn03540 rxn03541 rxn03895 rxn04045 rxn04046 rxn04047 rxn04048 rxn04050 rxn04052 rxn04148 rxn04149 rxn04150 rxn04151 rxn04152 rxn04153 rxn04154 rxn04158 rxn04159 rxn04160 rxn04161 rxn04162 rxn04163 rxn04164 rxn04384 rxn04385 rxn04386 rxn04413 rxn04704 rxn04705 rxn05029 rxn05054 rxn05120 rxn05121 rxn05809 rxn05810 rxn05811 rxn06171 rxn06339 rxn06454 rxn06455 rxn06456 rxn06591 rxn06598 rxn06789 rxn06826 rxn06827 rxn06828 rxn06839 rxn06887 rxn06979 rxn06980 rxn06981 rxn06982 rxn07586 rxn07587 rxn07588 rxn07589 rxn08194 rxn10476 rxn11593 rxn11640 rxn11641 rxn11650 rxn11665 rxn11666 rxn11667 rxn11991 rxn01470 rxn01658 rxn01660 rxn01661 rxn02064 rxn02109 rxn02147 rxn02148 rxn02657 rxn02658 rxn02692 rxn03449 rxn03450 rxn03843 rxn04147 rxn04308 rxn04379 rxn06150 rxn06266 rxn06267 rxn06340 rxn06852 rxn11611 rxn02311 rxn02535 rxn02631 rxn02704 rxn02722 rxn02819 rxn04006 rxn04007 rxn04057 rxn04058 rxn04059 rxn04060 rxn04061 rxn04062 rxn04065 rxn04066 rxn04067 rxn04076 rxn04077 rxn04078 rxn04079 rxn04080 rxn04081 rxn04083 rxn04086 rxn04087 rxn04088 rxn04089 rxn04091 rxn04097 rxn04098 rxn04101 rxn04102 rxn04103 rxn04104 rxn04105 rxn04106 rxn04107 rxn04108 rxn04109 rxn04110 rxn04111 rxn04112 rxn04114 rxn04115 rxn04116 rxn04117 rxn04118 rxn04119 rxn04120 rxn04121 rxn04122 rxn04123 rxn04125 rxn04128 rxn04129 rxn06985 rxn06987 rxn06988 rxn06989 rxn06992 rxn06993 rxn06994 rxn01467 rxn01468 rxn01469 rxn01471 rxn01473 rxn01566 rxn01787 rxn01850 rxn02336 rxn04018 rxn04019 rxn04136 rxn04279 rxn04280 rxn04281 rxn04282 rxn04283 rxn04284 rxn06073 rxn02772 rxn02837 rxn04034 rxn04234 rxn04237 rxn04238 rxn04239 rxn04240 rxn04241 rxn04242 rxn04243 rxn04244 rxn04245 rxn04246 rxn04247 rxn04248 rxn04249 rxn04250 rxn04251 rxn04252 rxn04253 rxn04254 rxn04255 rxn04256 rxn04257 rxn04258 rxn04259 rxn04260 rxn04261 rxn04262 rxn04263 rxn04264 rxn04265 rxn04266 rxn04267 rxn04268 rxn04269 rxn04270 rxn04271 rxn04274 rxn04275 rxn04276 rxn04277 rxn04278 rxn04373 rxn07101 rxn07102 rxn07103 rxn07104 rxn07105 rxn07106 rxn07107 rxn11668 rxn11669 rxn01488 rxn02157 rxn02158 rxn02697 rxn02698 rxn02699 rxn03452 rxn03453 rxn04145 rxn04146 rxn04165 rxn04166 rxn04167 rxn04168 rxn04169 rxn04170 rxn04171 rxn04173 rxn04174 rxn04175 rxn04176 rxn04177 rxn04178 rxn04179 rxn04180 rxn04181 rxn04182 rxn04183 rxn04184 rxn04185 rxn04186 rxn04187 rxn04188 rxn04189 rxn04190 rxn04191 rxn04192 rxn04194 rxn04195 rxn04196 rxn04197 rxn04198 rxn04199 rxn04200 rxn04201 rxn04202 rxn04203 rxn04204 rxn04205 rxn04206 rxn04207 rxn04208 rxn04209 rxn04210 rxn04211 rxn04212 rxn04213 rxn04214 rxn04215 rxn04216 rxn04217 rxn04218 rxn04219 rxn04220 rxn04222 rxn04223 rxn04224 rxn04225 rxn04226 rxn04227 rxn04228 rxn04229 rxn04230 rxn04231 rxn04232 rxn04468 rxn04469 rxn04470 rxn07097 rxn12020 rxn12021 rxn12022 rxn07271 rxn07272 rxn07273 rxn07274 rxn07275 rxn07277 rxn07278 rxn07280 rxn07281 rxn07282 rxn07283 rxn07284 rxn07285 rxn07286 rxn07287 rxn07288 rxn07289 rxn07290 rxn07298 rxn07299 rxn07300 rxn07301 rxn07302 rxn07303 rxn07304 rxn07305 rxn07306 rxn03646 rxn03648 rxn04755 rxn04756 rxn04757 rxn04758 rxn04759 rxn04760 rxn04761 rxn04762 rxn04763 rxn04764 rxn04765 rxn04766 rxn04767 rxn04768 rxn04771 rxn04772 rxn04962 rxn04963 rxn04978 rxn04979 rxn04981 rxn05068 rxn05069 rxn06790 rxn06792 rxn07347 rxn07348 rxn07350 rxn07351 rxn07352 rxn07353 rxn07354 rxn07355 rxn07356 rxn07357 rxn07358 rxn07359 rxn07360 rxn07363 rxn07364 rxn07365 rxn07366 rxn07367 rxn07368 rxn07369 rxn07370 rxn07372 rxn07374 rxn07375 rxn07376 rxn07377 rxn07378 rxn07385 rxn07386 rxn07387 rxn07388 rxn07389 rxn07390 rxn07394 rxn07399 rxn07402 rxn07403 rxn07404 rxn07405 rxn07406 rxn07407 rxn07408 rxn07409 rxn07410 rxn07411 rxn07412 rxn07468 rxn07469 rxn07470 rxn07471 rxn07625 rxn07631 rxn07632 rxn07633 rxn07634 rxn07635 rxn07636 rxn07637 rxn07638 rxn07639 rxn07640 rxn07643 rxn07646 rxn07647 rxn07648 rxn07706 rxn07891 rxn11574 rxn11619 rxn11620 rxn11625 rxn11684 rxn01527 rxn01528 rxn02247 rxn02645 rxn02836 rxn03972 rxn05022 rxn05933 rxn06952 rxn07841 rxn07842 rxn07843 rxn07850 rxn07851 rxn07852 rxn07855 rxn07856 rxn07857 rxn07858 rxn07860 rxn07861 rxn07862 rxn07863 rxn07864 rxn07865 rxn07866 rxn07867 rxn07868 rxn07869 rxn11509 rxn11693 rxn11694 rxn11695 rxn11696 rxn00019 rxn00102 rxn00109 rxn00112 rxn00339 rxn00349 rxn00567 rxn00568 rxn00569 rxn00570 rxn00571 rxn00572 rxn00573 rxn00574 rxn00820 rxn00908 rxn01016 rxn01806 rxn02529 rxn03978 rxn04138 rxn04467 rxn05778 rxn05779 rxn05890 rxn05893 rxn05894 rxn05895 rxn05977 rxn05980 rxn05993 rxn06246 rxn06874 rxn07053 rxn07054 rxn07055 rxn07056 rxn07058 rxn11973 rxn12822 rxn00360 rxn00378 rxn00380 rxn00381 rxn00383 rxn00565 rxn00623 rxn00625 rxn00755 rxn01357 rxn01415 rxn05239 rxn05877 rxn05902 rxn05904 rxn05946 rxn06114 rxn11645 rxn11934 rxn01597 rxn01598 rxn01600 rxn01866 rxn02347 rxn02348 rxn02663 rxn03455 rxn03456 rxn03546 rxn03595 rxn03657 rxn03797 rxn04023 rxn04471 rxn04472 rxn04749 rxn04750 rxn04751 rxn04752 rxn04753 rxn04754 rxn01180 rxn01181 rxn01182 rxn01425 rxn01427 rxn01570 rxn01571 rxn01589 rxn01590 rxn01613 rxn01712 rxn01713 rxn01714 rxn01814 rxn01815 rxn01887 rxn01888 rxn01889 rxn02118 rxn02207 rxn02382 rxn02413 rxn02414 rxn02415 rxn02554 rxn02556 rxn02568 rxn02574 rxn02575 rxn02634 rxn02758 rxn02814 rxn02815 rxn02816 rxn02968 rxn03203 rxn03402 rxn03403 rxn03970 rxn03971 rxn04423 rxn04424 rxn04425 rxn04426 rxn04427 rxn04428 rxn04429 rxn04430 rxn04431 rxn04432 rxn04433 rxn04434 rxn04437 rxn04438 rxn05142 rxn05143 rxn06186 rxn06530 rxn06552 rxn07276 rxn07617 rxn01179 rxn01559 rxn01765 rxn01767 rxn01769 rxn02074 rxn02238 rxn02239 rxn02241 rxn02564 rxn02598 rxn02601 rxn02602 rxn02979 rxn03352 rxn03353 rxn03411 rxn03412 rxn03413 rxn03414 rxn03989 rxn04387 rxn04388 rxn04394 rxn04395 rxn04406 rxn04411 rxn04422 rxn04462 rxn04466 rxn04635 rxn04637 rxn06166 rxn06317 rxn07116 rxn07777 rxn07778 rxn07779 rxn07780 rxn07781 rxn07782 rxn07783 rxn07784 rxn07785 rxn07786 rxn07787 rxn07788 rxn07789 rxn07790 rxn07791 rxn07792 rxn07793 rxn07794 rxn07796 rxn07797 rxn07798 rxn07799 rxn07800 rxn07802 rxn07803 rxn07811 rxn07812 rxn07816 rxn07818 rxn07819 rxn07821 rxn07822 rxn07870 rxn07871 rxn11515 rxn11516 rxn11670 rxn11671 rxn11672 rxn04389 rxn04390 rxn04391 rxn04402 rxn04403 rxn04404 rxn04614 rxn04615 rxn04616 rxn04617 rxn04618 rxn04632 rxn04633 rxn04634 rxn07111 rxn07112 rxn07113 rxn07114 rxn07663 rxn07664 rxn07665 rxn07666 rxn07667 rxn07668 rxn07669 rxn07670 rxn07672 rxn07673 rxn07674 rxn07675 rxn07676 rxn07690 rxn07691 rxn07693 rxn07694 rxn07695 rxn07696 rxn07697 rxn07698 rxn07699 rxn07700 rxn07701 rxn07702 rxn07703 rxn07704 rxn07705 rxn07713 rxn07714 rxn07715 rxn07716 rxn07717 rxn07718 rxn07719 rxn07720 rxn07721 rxn07722 rxn07728 rxn07734 rxn02098 rxn02099 rxn02119 rxn02156 rxn02470 rxn02784 rxn04415 rxn04416 rxn04417 rxn04419 rxn04458 rxn04459 rxn04607 rxn04608 rxn04609 rxn04610 rxn04611 rxn04974 rxn04975 rxn04976 rxn05032 rxn05033 rxn05065 rxn06278 rxn07525 rxn07528 rxn07529 rxn07530 rxn07531 rxn07532 rxn07533 rxn07534 rxn07535 rxn07536 rxn07537 rxn07538 rxn07539 rxn07540 rxn07542 rxn07543 rxn07545 rxn07546 rxn07547 rxn07549 rxn07550 rxn07551 rxn07552 rxn07553 rxn07554 rxn07555 rxn07556 rxn07557 rxn07558 rxn07559 rxn07560 rxn07561 rxn07562 rxn07563 rxn07564 rxn07565 rxn07566 rxn07567 rxn07568 rxn07569 rxn07570 rxn07571 rxn07590 rxn07591 rxn07592 rxn01556 rxn01557 rxn01558 rxn01907 rxn01908 rxn02354 rxn02472 rxn02548 rxn02551 rxn02561 rxn02562 rxn02563 rxn03120 rxn03165 rxn03351 rxn03633 rxn04463 rxn04612 rxn04619 rxn04620 rxn04622 rxn04623 rxn04624 rxn04630 rxn04631 rxn04642 rxn04643 rxn11513 rxn11514 rxn00035 rxn02067 rxn02396 rxn02627 rxn02641 rxn02642 rxn02710 rxn02711 rxn02712 rxn02713 rxn02857 rxn02858 rxn02997 rxn03051 rxn03206 rxn03207 rxn03208 rxn03210 rxn03211 rxn03212 rxn03213 rxn03214 rxn03215 rxn03216 rxn03217 rxn03218 rxn03219 rxn03220 rxn03221 rxn03222 rxn03231 rxn03261 rxn03472 rxn03473 rxn03474 rxn03475 rxn03476 rxn03525 rxn03526 rxn03527 rxn03528 rxn03529 rxn03530 rxn03531 rxn06501 rxn11615 rxn11618 rxn00015 rxn00854 rxn02033 rxn02543 rxn02654 rxn02702 rxn02828 rxn03477 rxn03478 rxn03479 rxn03480 rxn04555 rxn04556 rxn04557 rxn04558 rxn04559 rxn04560 rxn04561 rxn04562 rxn04564 rxn04565 rxn04566 rxn04567 rxn04568 rxn04569 rxn04570 rxn04571 rxn04573 rxn04574 rxn04576 rxn04594 rxn05850 rxn07148 rxn07149 rxn11675 rxn12076 rxn07461 rxn11747 rxn11751 rxn11752 rxn04807 rxn04808 rxn04809 rxn04810 rxn04811 rxn04812 rxn04813 rxn04814 rxn04815 rxn04816 rxn04817 rxn04818 rxn04819 rxn04820 rxn04821 rxn04822 rxn04823 rxn04824 rxn04825 rxn04826 rxn04827 rxn04828 rxn04829 rxn04830 rxn04831 rxn04832 rxn04833 rxn04834 rxn04835 rxn04836 rxn04837 rxn04869 rxn04871 rxn04872 rxn04873 rxn04874 rxn04875 rxn04876 rxn04877 rxn04878 rxn04879 rxn04880 rxn04881 rxn04882 rxn04883 rxn04884 rxn04885 rxn04886 rxn04887 rxn04888 rxn04889 rxn04890 rxn04891 rxn04892 rxn04893 rxn04894 rxn04895 rxn04896 rxn04898 rxn04901 rxn04902 rxn04903 rxn04904 rxn04905 rxn04906 rxn04907 rxn04908 rxn04909 rxn04910 rxn04915 rxn04916 rxn04917 rxn04918 rxn04919 rxn04920 rxn04921 rxn04922 rxn04923 rxn04926 rxn04927 rxn07181 rxn07182 rxn07183 rxn01707 rxn06161 rxn11517 rxn11518 rxn11519 rxn11520 rxn11521 rxn11522 rxn11523 rxn11524 rxn11525 rxn11526 rxn11527 rxn11528 rxn11529 rxn11530 rxn11531 rxn11532 rxn11533 rxn11534 rxn11535 rxn11536 rxn11537 rxn11538 rxn11539 rxn11540 rxn11541 rxn11542 rxn11789 rxn11790 rxn11791 rxn11794 rxn11795 rxn11796 rxn11797 rxn11798 rxn11799 rxn11800 rxn11802 rxn11803 rxn11804 rxn11805 rxn11806 rxn11807 rxn11808 rxn11809 rxn11810 rxn11811 rxn11812 rxn11813 rxn11814 rxn11815 rxn11816 rxn11817 rxn11818 rxn11819 rxn11820 rxn11821 rxn11822 rxn11824 rxn11825 rxn11826 rxn11827 rxn11828 rxn11829 rxn11831 rxn11832 rxn11834 rxn11835 rxn11837 rxn11838 rxn11840 rxn11841 rxn11842 rxn11843 rxn11844 rxn11845 rxn11846 rxn11847 rxn11848 rxn11849 rxn11850 rxn11851 rxn11852 rxn11853 rxn11854 rxn11856 rxn11857 rxn11860 rxn11861 rxn11862 rxn11863 rxn11864 rxn11865 rxn11866 rxn11867 rxn11868 rxn11869 rxn11870 rxn11871 rxn11872 rxn11875 rxn11876 rxn12031 rxn12032 rxn12033 rxn12034 rxn12035 rxn12036 rxn12037 rxn12038 rxn12039 rxn11749 rxn11750 rxn11754 rxn11755 rxn11756 rxn11757 rxn11758 rxn11759 rxn11760 rxn11761 rxn11762 rxn11763 rxn11764 rxn11765 rxn11766 rxn11767 rxn11768 rxn11771 rxn11772 rxn11773 rxn11774 rxn11776 rxn11777 rxn11778 rxn11779 rxn11781 rxn11782 rxn11784 rxn11787 rxn11788 rxn12023 rxn12024 rxn12025 rxn12026 rxn12027 rxn12028 rxn12029 rxn12030 rxn06134 rxn06492 rxn07572 rxn07573 rxn07574 rxn07575 rxn07723 rxn07724 rxn07725 rxn07726 rxn07727 rxn07740 rxn07741 rxn07742 rxn07743 rxn08444 rxn11710 rxn11711 rxn11712 rxn11713 rxn11714 rxn11715 rxn11716 rxn11717 rxn11718 rxn11719 rxn11720 rxn11721 rxn11722 rxn11723 rxn11724 rxn11725 rxn11726 rxn11727 rxn11801 rxn04439 rxn04440 rxn04441 rxn04442 rxn04443 rxn04444 rxn04445 rxn04446 rxn04447 rxn04448 rxn04805 rxn01094 rxn02177 rxn04454 rxn04455 rxn04473 rxn04474 rxn04475 rxn04476 rxn04477 rxn04478 rxn04479 rxn04480 rxn04482 rxn04483 rxn11674 rxn07125 rxn07126 rxn07127 rxn07128 rxn07129 rxn07130 rxn07131 rxn07132 rxn07133 rxn07134 rxn07135 rxn07136 rxn07137 rxn07138 rxn04484 rxn04490 rxn04493 rxn04494 rxn04495 rxn04497 rxn04498 rxn04499 rxn04500 rxn04501 rxn04502 rxn04503 rxn04505 rxn04507 rxn04508 rxn04509 rxn04510 rxn04511 rxn04512 rxn04513 rxn04514 rxn04515 rxn04516 rxn04517 rxn04518 rxn04519 rxn04520 rxn04521 rxn04522 rxn04523 rxn04524 rxn04525 rxn04526 rxn04527 rxn04528 rxn04529 rxn04532 rxn04533 rxn04534 rxn04535 rxn04536 rxn04540 rxn04544 rxn04546 rxn04547 rxn04548 rxn04549 rxn04550 rxn04551 rxn04552 rxn04553 rxn04554 rxn07139 rxn07140 rxn07141 rxn07142 rxn07143 rxn07144 rxn00725 rxn05016 rxn05125 rxn06972 rxn06976 rxn07174 rxn01241 rxn00011 rxn00305 rxn00519 rxn01871 rxn02342 rxn05938 rxn00247 rxn01977 rxn00545 rxn00549 rxn00786 rxn00558 rxn00747 rxn00220 rxn00216 rxn00704 rxn00148 rxn00705 rxn00499 rxn00506 rxn00507 rxn00781 rxn00782 rxn01100 rxn00175 rxn00250 rxn00248 rxn00256 rxn00974 rxn01388 rxn05836 rxn00306 rxn00285 rxn00257 rxn00799 rxn05939 rxn01123 rxn03884 rxn01116 rxn00770 rxn00778 rxn01115 rxn01475 rxn01975 rxn01187 rxn00777 rxn00785 rxn01200 rxn00501 rxn00502 rxn00879 rxn02007 rxn00213 rxn01006 rxn01077 rxn01079 rxn01911 rxn01912 rxn02321 rxn03111 rxn03274 rxn04082 rxn04928 rxn04930 rxn00211 rxn05992 rxn06005 rxn06064 rxn03644 rxn00547 rxn00575 rxn00214 rxn00355 rxn00701 rxn00444 rxn00821 rxn00880 rxn06369 rxn07576 rxn07577 rxn07578 rxn07579 rxn00874 rxn02680 rxn02804 rxn02911 rxn03239 rxn03240 rxn03241 rxn03242 rxn03243 rxn03244 rxn03245 rxn03246 rxn03247 rxn03248 rxn03249 rxn03250 rxn06510 rxn06777 rxn00943 rxn00178 rxn01730 rxn02167 rxn01451 rxn02345 rxn00290 rxn00991 rxn01454 rxn00995 rxn00992 rxn03281 rxn00830 rxn01213 rxn01466 rxn01486 rxn02640 rxn01258 rxn01690 rxn00101 rxn00113 rxn00802 rxn01434 rxn00127 rxn01021 rxn01022 rxn01406 rxn00394 rxn01019 rxn01851 rxn02061 rxn00470 rxn00002 rxn00790 rxn00917 rxn00114 rxn00800 rxn00838 rxn01968 rxn03004 rxn03137 rxn00359 rxn00361 rxn00379 rxn00414 rxn01018 rxn00654 rxn00719 rxn00720 rxn01626 rxn00212 rxn01223 rxn01520 rxn04464 rxn00191 rxn00260 rxn00503 rxn00504 rxn00182 rxn00184 rxn00508 rxn00509 rxn00193 rxn00189 rxn00555 rxn00194 rxn01204 rxn00190 rxn06937 rxn00069 rxn00085 rxn00187 rxn06436 rxn06437 rxn10534 rxn05984 rxn00272 rxn00864 rxn00865 rxn00346 rxn00656 rxn00657 rxn00340 rxn00342 rxn00283 rxn00347 rxn00416 rxn06300 rxn06433 rxn06434 rxn06936 rxn11595 rxn00533 rxn02851 rxn03756 rxn03761 rxn06915 rxn06916 rxn06918 rxn00953 rxn02028 rxn00742 rxn00737 rxn00337 rxn01301 rxn01302 rxn01643 rxn00404 rxn01373 rxn00692 rxn01102 rxn00751 rxn05964 rxn05970 rxn06044 rxn06087 rxn06090 rxn06091 rxn06376 rxn01011 rxn01013 rxn06600 rxn00599 rxn06438 rxn06446 rxn06447 rxn00455 rxn00693 rxn06538 rxn00950 rxn01303 rxn01304 rxn01816 rxn06443 rxn00647 rxn00645 rxn00651 rxn00423 rxn00649 rxn06435 rxn00804 rxn00806 rxn01575 rxn00903 rxn00602 rxn00671 rxn01355 rxn01996 rxn00902 rxn02185 rxn00735 rxn02749 rxn02751 rxn00898 rxn06440 rxn06441 rxn06449 rxn00510 rxn00511 rxn01423 rxn01663 rxn02011 rxn03164 rxn00202 rxn06442 rxn06172 rxn00322 rxn00328 rxn06432 rxn06445 rxn02352 rxn02353 rxn00375 rxn00376 rxn01641 rxn00867 rxn06439 rxn00527 rxn00522 rxn00993 rxn01825 rxn02276 rxn00521 rxn00530 rxn00529 rxn01716 rxn00540 rxn01893 rxn00487 rxn00488 rxn00493 rxn01840 rxn01843 rxn00495 rxn01611 rxn01612 rxn03699 rxn03599 rxn06986 rxn00957 rxn00958 rxn00960 rxn00962 rxn01189 rxn01192 rxn01193 rxn01896 rxn01894 rxn02788 rxn02948 rxn00587 rxn00588 rxn00592 rxn00594 rxn00595 rxn00722 rxn00584 rxn00959 rxn03897 rxn03898 rxn00004 rxn03442 rxn01437 rxn00484 rxn00473 rxn06448 rxn01268 rxn01682 rxn06280 rxn06444 rxn00174 rxn00534 rxn01174 rxn01177 rxn02181 rxn02182 rxn02261 rxn01791 rxn00173 rxn00225 rxn00278 rxn01234 rxn03369 rxn09244 rxn00388 rxn02008 rxn02286 rxn01153 rxn00851 rxn00198 rxn06050 rxn05800 rxn05807 rxn01007 rxn01008 rxn06535 rxn06000 rxn06036 rxn01675 rxn02000 rxn02003 rxn01997 rxn04027 rxn00609 rxn00881 rxn04290 rxn05901 rxn06138 rxn06140 rxn06139 rxn01879 rxn00882 rxn00883 rxn02388 rxn02434 rxn02435 rxn02455 rxn02457 rxn02458 rxn02460 rxn02489 rxn03035 rxn03519 rxn06365 rxn06366 rxn06367 rxn06378 rxn06389 rxn06682 rxn06716 rxn06721 rxn06977 rxn06043 rxn06046 rxn00146 rxn00330 rxn00677 rxn00157 rxn00177 rxn00151 rxn00159 rxn00161 rxn00249 rxn01667 rxn00251 rxn00147 rxn00589 rxn00723 rxn00690 rxn00691 rxn00907 rxn01211 rxn00371 rxn05759 rxn05887 rxn00374 rxn01452 rxn02169 rxn02123 rxn12823 rxn02113 rxn00288 rxn00803 rxn00003 rxn02625 rxn00910 rxn04954 rxn00686 rxn01602 rxn02431 rxn02480 rxn02897 rxn03150 rxn00138 rxn02053 rxn02536 rxn02537 rxn02655 rxn01786 rxn01788 rxn02234 rxn04134 rxn04135 rxn01490 rxn07361 rxn07362 rxn07392 rxn07395 rxn07397 rxn07400 rxn00949 rxn01426 rxn01429 rxn01743 rxn03016 rxn05136 rxn05137 rxn05139 rxn07118 rxn01768 rxn07526 rxn04392 rxn04393 rxn07115 rxn11992)];
		foreach my $rxn (@{$rxns}) {
			$keggmaphash->{$rxn} = 1;
		}
	}
	return $keggmaphash;
}

sub runexecutable {
	my ($Command) = @_;
	my $OutputArray;
	push(@{$OutputArray},`$Command`);
	return $OutputArray;
}

sub IsCofactor {
	my ($cpdid) = @_;
	my $hash = {
		cpd00001 => 1,
		cpd00002 => 1,
		cpd00003 => 1,
		cpd00004 => 1,
		cpd00005 => 1,
		cpd00006 => 1,
		cpd00007 => 1,
		cpd00008 => 1,
		cpd00009 => 1,
		cpd00010 => 1,
		cpd00011 => 1,
		cpd00012 => 1,
		cpd00013 => 1,
		cpd00014 => 1,
		cpd00015 => 1,
		cpd00018 => 1,
		cpd00021 => 1,
		cpd00030 => 1,
		cpd00031 => 1,
		cpd00034 => 1,
		cpd00038 => 1,
		cpd00046 => 1,
		cpd00048 => 1,
		cpd00050 => 1,
		cpd00052 => 1,
		cpd00053 => 1,
		cpd00058 => 1,
		cpd00062 => 1,
		cpd00063 => 1,
		cpd00067 => 1,
		cpd00068 => 1,
		cpd00074 => 1,
		cpd00075 => 1,
		cpd00081 => 1,
		cpd00090 => 1,
		cpd00091 => 1,
		cpd00096 => 1,
		cpd00099 => 1,
		cpd00114 => 1,
		cpd00115 => 1,
		cpd00126 => 1,
		cpd00149 => 1,
		cpd00150 => 1,
		cpd00173 => 1,
		cpd00177 => 1,
		cpd00186 => 1,
		cpd00204 => 1,
		cpd00205 => 1,
		cpd00206 => 1,
		cpd00209 => 1,
		cpd00239 => 1,
		cpd00241 => 1,
		cpd00242 => 1,
		cpd00244 => 1,
		cpd00294 => 1,
		cpd00295 => 1,
		cpd00296 => 1,
		cpd00297 => 1,
		cpd00298 => 1,
		cpd00299 => 1,
		cpd00354 => 1,
		cpd00356 => 1,
		cpd00357 => 1,
		cpd00358 => 1
	};
	if (defined($hash->{$cpdid})) {
		return 1;
	}
	return 0;
}

sub set_global {
	my ($parameter,$value) = @_;
	$globalparams->{$parameter} = $value;
}

sub get_global {
	my ($parameter) = @_;
	return $globalparams->{$parameter};
}

sub load_config {
	my ($args) = @_;
	$args = Bio::KBase::ObjectAPI::utilities::ARGS($args,[],{
		filename => $ENV{KB_DEPLOYMENT_CONFIG},
		service => $ENV{KB_SERVICE_NAME},
	});
	if (!defined($args->{service})) {
		Bio::KBase::ObjectAPI::utilities::error("No service specified!");
	}
	if (!defined($args->{filename})) {
		Bio::KBase::ObjectAPI::utilities::error("No config file specified!");
	}
	if (!-e $args->{filename}) {
		Bio::KBase::ObjectAPI::utilities::error("Specified config file ".$args->{filename}." doesn't exist!");
	}
	my $c = Config::Simple->new();
	$c->read($args->{filename});
	my $hash = $c->vars();
	my $service_config = {};
	foreach my $key (keys(%{$hash})) {
		my $array = [split(/\./,$key)];
		if ($array->[0] eq $args->{service}) {
			if ($hash->{$key} ne "null") {
				$service_config->{$array->[1]} = $hash->{$key};
			}
		}
	}
	return $service_config;
}

sub rest_download {
	my ($args,$params) = @_;
	$args = Bio::KBase::ObjectAPI::utilities::ARGS($args,["url"],{
		retry => 5,
		token => undef
	});
	my $ua = LWP::UserAgent->new();
	if (defined($args->{token})) {
		$ua->default_header( "Authorization" => $args->{token} );
	}
	for (my $i=0; $i < $args->{retry}; $i++) {
		my $res = $ua->get($args->{url});
		if ($res->{_msg} ne "Bad Gateway") {
			if (defined($res->{_headers}->{"content-range"}) && $res->{_headers}->{"content-range"} =~ m/\/(.+)/) {
				$params->{count} = $1;
			}
			return Bio::KBase::ObjectAPI::utilities::FROMJSON($res->{_content});
		} else {
		}
	}
	Bio::KBase::ObjectAPI::utilities::error("REST download failed at URL:".$args->{url});
}

sub elaspedtime {
	if (!defined($startime)) {
		$startime = time();
	}
	return time()-$startime;
}

sub kblogin {
	my $params = shift;
	my $url = "https://kbase.us/services/authorization/Sessions/Login";
	my $content = {
		user_id => $params->{user_id},
		password => $params->{password},
		status => 1,
		fields => "un,token,user_id,kbase_sessionid,name"
	};
	my $ua = LWP::UserAgent->new();
	my $res = $ua->post($url,$content);
	if (!$res->is_success) {
    	Bio::KBase::ObjectAPI::utilities::error("KBase login failed!");
	}
	my $data = decode_json $res->content;
	return $data->{token};
}

sub classifier_data {
	if (!defined($classifierdata)) {
		my $data;
		if (Bio::KBase::ObjectAPI::config::classifier() =~ m/^WS:(.+)/) {
			$data = Bio::KBase::ObjectAPI::functions::util_get_object($1);
			$data = [split(/\n/,$data)];
		} else {
			if (!-e Bio::KBase::ObjectAPI::config::classifier()) {
				system("curl https://raw.githubusercontent.com/kbase/KBaseFBAModeling/dev/classifier/classifier.txt > ".Bio::KBase::ObjectAPI::config::classifier());
			}
			$data = Bio::KBase::ObjectAPI::utilities::LOADFILE(Bio::KBase::ObjectAPI::config::classifier());
		}
		my $headings = [split(/\t/,$data->[0])];
		my $popprob = [split(/\t/,$data->[1])];
		for (my $i=1; $i < @{$headings}; $i++) {
			$classifierdata->{classifierClassifications}->{$headings->[$i]} = {
				name => $headings->[$i],
				populationProbability => $popprob->[$i]
			};
		}
		my $cfRoleHash = {};
		for (my $i=2;$i < @{$data}; $i++) {
			my $row = [split(/\t/,$data->[$i])];
			my $searchrole = Bio::KBase::ObjectAPI::utilities::convertRoleToSearchRole($row->[0]);
			$classifierdata->{classifierRoles}->{$searchrole} = {
				classificationProbabilities => {},
				role => $row->[0]
			};
			for (my $j=1; $j < @{$headings}; $j++) {
				$classifierdata->{classifierRoles}->{$searchrole}->{classificationProbabilities}->{$headings->[$j]} = $row->[$j];
			}
		}
	}
	return $classifierdata;
}

1;
