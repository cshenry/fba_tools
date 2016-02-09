#!/bin/bash
script_dir=$(dirname "$(readlink -f "$0")")
export KB_DEPLOYMENT_CONFIG=$script_dir/../deploy.cfg
export KB_AUTH_TOKEN=`cat /kb/module/work/token`
export PERL5LIB=$script_dir/../lib:$PATH:$PERL5LIB
cd $script_dir/../test
perl -e 'opendir my $dh, "."; my @l = grep { /\.pl$/ } readdir $dh; foreach my $s (@l) { print("Running ".$s."
"); system "perl", $s; }'
