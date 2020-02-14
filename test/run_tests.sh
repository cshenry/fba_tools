#!/bin/bash
script_dir=$(dirname "$(readlink -f "$0")")
export KB_DEPLOYMENT_CONFIG=$script_dir/../testdeploy.cfg
export KB_AUTH_TOKEN=`cat /kb/module/work/token`
export PERL5LIB=$script_dir/../lib:$PATH:$PERL5LIB
cd $script_dir/..
prove -lvrm $(TEST_DIR)
prove -lvm --ext pl $(TEST_DIR)