#!/bin/bash
script_dir=$(dirname "$(readlink -f "$0")")
export PERL5LIB=$script_dir/../lib:$PATH:$PERL5LIB
perl $script_dir/../lib/fba_tools/fba_toolsServer.pm $1 $2 $3
