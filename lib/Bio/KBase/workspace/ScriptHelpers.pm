package Bio::KBase::workspace::ScriptHelpers;
use strict;
use warnings;
use Bio::KBase::workspace::Client;
use Bio::KBase::workspace::ScriptConfig;
use Bio::KBase::Auth;
#use Bio::KBase::userandjobstate::Client; #no longer needed
use Exporter;
use Config::Simple;
use Data::Dumper;
use parent qw(Exporter);
our @EXPORT_OK = qw(	loadTableFile
			printJobData
			getToken
			getUser
			get_ws_client
			workspace workspaceURL
			getObjectRef
			parseObjectMeta
			parseWorkspaceInfo
			parseWorkspaceMeta
			printObjectMeta
			printWorkspaceMeta
			parseObjectInfo
			printObjectInfo);

## URLs are now set in Bio::KBase::workspace::ScriptUrl:ScriptConfig; this module
## is generated and configurable from the makefile target "set-default-script-url"
## our $defaultURL = "https://kbase.us/services/ws";
##our $localhostURL = "http://127.0.0.1:7058";
##our $devURL = "http://140.221.84.209:7058";

#
# TODO: instead of hardcoding the variable names in client config file, set them as module constants....
#        .... the number of config variables is starting to proliferate! ....
#

sub get_ws_client {
	my $url = shift;
	if (!defined($url)) {
		$url = workspaceURL();
	}
	return Bio::KBase::workspace::Client->new($url);
}

sub getToken {
	my $token='';
	my $kbConfPath = $Bio::KBase::Auth::ConfPath;
	if (defined($ENV{KB_RUNNING_IN_IRIS})) {
		$token = $ENV{KB_AUTH_TOKEN};
	} elsif ( -e $kbConfPath ) {
		my $cfg = new Config::Simple($kbConfPath);
		$token = $cfg->param("authentication.token");
		$cfg->close();
	}
	return $token;
}

# WARNING - IN IRIS, THIS ALWAYS RETURNS EMPTY STRING, NOT THE USER ID
sub getUser {
	my $user_id='';
	my $kbConfPath = $Bio::KBase::Auth::ConfPath;
	if (defined($ENV{KB_RUNNING_IN_IRIS})) {
		$user_id = "";
	} elsif ( -e $kbConfPath ) {
		my $cfg = new Config::Simple($kbConfPath);
		$user_id = $cfg->param("authentication.user_id");
		$cfg->close();
	}
	return $user_id;
}


sub getKBaseCfg {
	my $kbConfPath = $Bio::KBase::Auth::ConfPath;
	if (!-e $kbConfPath) {
		my $newcfg = new Config::Simple(syntax=>'ini') or die Config::Simple->error();
		$newcfg->param("workspace_deluxe.url",$Bio::KBase::workspace::ScriptConfig::defaultURL);
		$newcfg->write($kbConfPath);
		$newcfg->close();
	}
	my $cfg = new Config::Simple(filename=>$kbConfPath,syntax=>'ini') or die Config::Simple->error();
	return $cfg;
}


sub workspace {
        my $newWs = shift;
        my $currentWs;
        if (defined($newWs)) {
                $currentWs = $newWs;
		# if we are on the file system, then save the workspace to the kbase config file
		# prefixed by the user name
                #if (!defined($ENV{KB_RUNNING_IN_IRIS})) {  ### NOTE: IRIS NOW SUPPORTS CLIENT CFG FILE, SO NO CHECK NEEDED HERE
                        my $cfg = getKBaseCfg();
			my $user_id = getUser(); #$cfg->param("authentication.user_id");
			#Note: cfg lib will return ref to a list if the variable is not set!  make sure that the url isn't a ref
			if (!defined($user_id) || (ref($user_id) ne '')) { $user_id='public'; }
                        $cfg->param("workspace_deluxe.$user_id-current-workspace",$newWs);
                        $cfg->save();
                        $cfg->close();
                #}
		# otherwise we are in an IRIS environment, so save using the UJS (in which case
		# the user must be logged in)
		#else {
		#	my $ujs = Bio::KBase::userandjobstate::Client->new();
		#	$ujs->set_state("Workspace","current-workspace",$currentWs);
                #}
        } else {
		# if we are not running in IRIS, check the config file first to see if the ws is defined
                #if (!defined($ENV{KB_RUNNING_IN_IRIS})) { ### NOTE: IRIS NOW SUPPORTS CLIENT CFG FILE, SO NO CHECK NEEDED HERE
                        my $cfg = getKBaseCfg();
			my $user_id = getUser(); #$cfg->param("authentication.user_id");
			if (!defined($user_id) || (ref($user_id) ne '')) { $user_id='public'; }
                        $currentWs = $cfg->param("workspace_deluxe.$user_id-current-workspace");
			# handle old config file style if that was not found, but save back in the
			# new config style
			#Note: cfg lib will return ref to a list if the variable is not set!  make sure that the url isn't a ref
			if (!defined($currentWs) || (ref($currentWs) ne '')) {
				$currentWs = $cfg->param("workspace_deluxe.workspace");
				if (defined($currentWs)) {
					$cfg->param("workspace_deluxe.$user_id-current-workspace",$currentWs);
					$cfg->delete("workspace_deluxe.workspace");
					$cfg->save();
				}
				else {
					print STDERR "\nWarning! Workspace has not been set!\nRun ws-workspace [WORKSPACE_NAME] to set your workspace.\n\n";
					$currentWs = "";
					
					# if we could not find from the config file, then lookup from UJS and save it to our local config file
					#my $ujs = Bio::KBase::userandjobstate::Client->new();
					#eval { $currentWs = $ujs->get_state("Workspace","current-workspace",0); };
					#if($@ || !defined($currentWs)) {
					#	print STDERR "\nWarning! Workspace has not been set!\nRun ws-workspace [WORKSPACE_NAME] to set your workspace.\n\n";
					#	$currentWs = "";
					#} else {
					#	$cfg->param("workspace_deluxe.$user_id-current-workspace",$currentWs);
					#	$cfg->save();
					#}
				}
			}
                        $cfg->close();
                #}
		### NOTE: IRIS NOW SUPPORTS CLIENT CFG FILE, SO NO CHECK NEEDED HERE
		# we are in IRIS, so we always lookup based on the UJS
		#else {
		#	my $ujs = Bio::KBase::userandjobstate::Client->new();
		#	eval { $currentWs = $ujs->get_state("Workspace","current-workspace",0); };
		#	if($@ || !defined($currentWs)) {
		#		print STDERR "\nWarning! Workspace has not been set!\nRun ws-workspace [WORKSPACE_NAME] to set your workspace.\n\n";
		#		$currentWs = "";
		#	}
                #}
        }
        return $currentWs;
}


sub workspaceURL {
	my $newUrl = shift;
	my $currentURL;
	if (defined($newUrl)) {
		
		# handle cases where we want to switch to a URL by name
		if ($newUrl eq "default") {
			$newUrl = $Bio::KBase::workspace::ScriptConfig::defaultURL;
		} elsif ($newUrl eq "prod") {
			$newUrl = $Bio::KBase::workspace::ScriptConfig::defaultURL;
		}elsif ($newUrl eq "localhost") {
			$newUrl = $Bio::KBase::workspace::ScriptConfig::localhostURL;
		} elsif ($newUrl eq "dev") {
			$newUrl = $Bio::KBase::workspace::ScriptConfig::devURL;
		}
		
		# save the configured URL
		#if (!defined($ENV{KB_RUNNING_IN_IRIS})) { ### NOTE: IRIS NOW SUPPORTS CLIENT CFG FILE, SO NO CHECK NEEDED HERE
			my $cfg = getKBaseCfg();
			$cfg->param("workspace_deluxe.url",$newUrl);
			$cfg->save();
			$cfg->close();
		#} else {
		#	my $ujs = Bio::KBase::userandjobstate::Client->new();
		#	$ujs->set_state("Workspace","current-workspace-url",$newUrl);
		#}
		
		#return the url
		$currentURL = $newUrl;
	} else {
		
		# if we are on the file system, lookup the URL in the config file.  If that isn't possible,
		# then we return the default URL
		#if (!defined($ENV{KB_RUNNING_IN_IRIS})) {
			my $cfg = getKBaseCfg();
			$currentURL = $cfg->param("workspace_deluxe.url");
			#Note: cfg lib will return ref to a list if the variable is not set!  make sure that the url isn't a ref
			if (!defined($currentURL) || (ref($currentURL) ne '')) {  
				$cfg->param("workspace_deluxe.url",$Bio::KBase::workspace::ScriptConfig::defaultURL);
				$cfg->save();
				$currentURL=$Bio::KBase::workspace::ScriptConfig::defaultURL;
			}
			$cfg->close();
		#}
		# same thing in IRIS except we use the UJS to store the URL
		#else {
		#	my $ujs = Bio::KBase::userandjobstate::Client->new();
		#	eval { $currentURL = $ujs->get_state("Workspace","current-workspace-url",0); };
		#	# if no URL was set, we just assume the default URL
		#	if($@ || !defined($currentURL)) {
		#		$currentURL = $Bio::KBase::workspace::ScriptConfig::defaultURL;
		#	}
		#}
	}
	return $currentURL;
}


# given the strings passed to a script as an ws, object name, and version returns
# the reference string of the object. The magic is that if, in the object name,
# it is a reference to begin with, then that reference information overrides
# what is passed in as other args or if there is a default workspace set.
sub getObjectRef {
	my($ws,$obj,$ver) = @_;
	my $versionString = '';
	if (defined($ver)) { if($ver ne '') { $versionString="/".$ver;} }
	
	# check for refs of the form kb|ws.1.obj.2.ver.4
	my @idtokens = split(/\./,$obj);
	if (scalar(@idtokens)==4) {
		if ($idtokens[0] eq 'kb|ws' && $idtokens[2] eq 'obj' && $idtokens[1]=~/^\d+$/ && $idtokens[3]=~/^\d+$/) {
			return $idtokens[1]."/".$idtokens[3].$versionString;
		}
	} elsif(scalar(@idtokens)==6) {
		if ($idtokens[0] eq 'kb|ws' && $idtokens[2] eq 'obj' && $idtokens[4] eq 'ver' && $idtokens[1]=~/^\d+$/ && $idtokens[3]=~/^\d+$/ && $idtokens[5]=~/^\d+$/) {
			return $idtokens[1]."/".$idtokens[3]."/".$idtokens[5];
		}
	}
	
	# check for refs of the form ws/obj/ver
	my @tokens = split(/\//, $obj);
	if (scalar(@tokens)==1) {
		return $ws."/".$obj.$versionString;
	} elsif (scalar(@tokens)==2) {
		return $tokens[0]."/".$tokens[1].$versionString;
	} elsif (scalar(@tokens)==3) {
		return $obj;
	}
	
	#should never get here!!!
	return $ws."/".$obj.$versionString;
}


sub parseObjectMeta {
	my $object = shift;
	my $hash = {
		id => $object->[0],
		type => $object->[1],
		moddate => $object->[2],
		instance => $object->[3],
		command => $object->[4],
		lastmodifier => $object->[5],
		owner => $object->[6],
		workspace => $object->[7],
		reference => $object->[8],
		chsum => $object->[9],
		metadata => $object->[10]
	};
	return $hash;
}

sub printObjectMeta {
	my $meta = shift;
	my $obj = parseObjectMeta($meta);
	print "Object Name: ".$obj->{id}."\n";
	print "Type: ".$obj->{type}."\n";
	print "Instance: ".$obj->{instance}."\n";
	print "Workspace: ".$obj->{workspace}."\n";
	print "Owner: ".$obj->{owner}."\n";
	print "Moddate: ".$obj->{moddate}."\n";
	#print "Last cmd: ".$obj->{command}."\n";
	print "Modified by: ".$obj->{lastmodifier}."\n";
	#print "Perm ref: ".$obj->{reference}."\n";
	print "Checksum: ".$obj->{chsum}."\n";
	if (defined($obj->{metadata})) {
		foreach my $key (keys(%{$obj->{metadata}})) {
			print $key.": ".$obj->{metadata}->{$key}."\n";
		}
	}
}


sub parseObjectInfo {
	my $object = shift;
	my $hash = {
		id => $object->[0],
		name => $object->[1],
		type => $object->[2],
		save_date => $object->[3],
		version => $object->[4],
		saved_by => $object->[5],
		wsid => $object->[6],
		workspace => $object->[7],
		chsum => $object->[8],
		size => $object->[9],
		metadata => $object->[10]
	};
	return $hash;
}

sub printObjectInfo {
	my $meta = shift;
	my $obj = parseObjectInfo($meta);
	print "Object Name: ".$obj->{name}."\n";
	print "Object ID: ".$obj->{id}."\n";
	print "Type: ".$obj->{type}."\n";
	print "Version: ".$obj->{version}."\n";
	print "Workspace: ".$obj->{workspace}."\n";
	print "Save Date: ".$obj->{save_date}."\n";
	print "Saved by: ".$obj->{saved_by}."\n";
	print "Checksum: ".$obj->{chsum}."\n";
	print "Size(bytes): ".$obj->{size}."\n";
	print "User Meta Data: ";
	if (defined($obj->{metadata})) {
		if (scalar(keys(%{$obj->{metadata}}))>0) { print "\n"; }
		else { print " none.\n"; }
		foreach my $key (keys(%{$obj->{metadata}})) {
			print "  ".$key.": ".$obj->{metadata}->{$key}."\n";
		}
	} else {
		print "none.\n";
	}
}



sub parseWorkspaceInfo {
	my $object = shift;
	my $hash = {
		id => $object->[0],
		workspace => $object->[1],
		owner => $object->[2],
		moddate => $object->[3],
		objects => $object->[4],
		user_permission => $object->[5],
		globalread => $object->[6]
	};
	return $hash;
}

sub parseWorkspaceMeta {
	my $object = shift;
	my $hash = {
		id => $object->[0],
		owner => $object->[1],
		moddate => $object->[2],
		objects => $object->[3],
		user_permission => $object->[4],
		global_permission => $object->[5],
	};
	return $hash;
}

sub printWorkspaceMeta {
	my $meta = shift;
	my $obj = parseWorkspaceMeta($meta);
	print "Workspace ID: ".$obj->{id}."\n";
	print "Owner: ".$obj->{owner}."\n";
	print "Moddate: ".$obj->{moddate}."\n";
	print "Objects: ".$obj->{objects}."\n";
	print "User permission: ".$obj->{user_permission}."\n";
	print "Global permission:".$obj->{global_permission}."\n";
}

sub loadTableFile {
	my ($filename) = @_;
	if (!-e $filename) {
		print "Could not open table file ".$filename."!\n";
		exit();
	}
	open(my $fh, "<", $filename) || return;
	my $headingline = <$fh>;
	my $tbl;
	chomp($headingline);
	my $headings = [split(/\t/,$headingline)];
	for (my $i=0; $i < @{$headings}; $i++) {
		$tbl->{headings}->{$headings->[$i]} = $i;
	}
	while (my $line = <$fh>) {
		chomp($line);
		push(@{$tbl->{data}},[split(/\t/,$line)]);
	}
	close($fh);
	return $tbl;
}

1;
