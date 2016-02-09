#!/bin/bash
script_dir=$(dirname "$(readlink -f "$0")")
export KB_DEPLOYMENT_CONFIG=$script_dir/../deploy.cfg
export PERL5LIB=$script_dir/../lib:$PATH:$PERL5LIB
plackup $script_dir/../lib/fba_tools.psgi
