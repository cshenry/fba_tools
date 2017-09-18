#!/bin/bash

. /kb/deployment/user-env.sh

python ./scripts/prepare_deploy_cfg.py ./deploy.cfg ./work/config.properties

if [ $# -eq 0 ] ; then
  sh ./scripts/start_server.sh
elif [ "${1}" = "test" ] ; then
  echo "Run Tests"
  make test
elif [ "${1}" = "async" ] ; then
  sh ./scripts/run_async.sh
elif [ "${1}" = "init" ] ; then
  echo "Initialize module"
  cd /data
  curl http://bioseed.mcs.anl.gov/~chenry/Reactions.json > /data/Reactions.json
  curl http://bioseed.mcs.anl.gov/~chenry/Compounds.json > /data/Compounds.json
  curl http://bioseed.mcs.anl.gov/~chenry/KEGG_pathways > /data/KEGG_pathways
  if [ -e /data/Reactions.json ] ; then
  	touch __READY__
  else
    echo "Init failed"
  fi
elif [ "${1}" = "bash" ] ; then
  bash
elif [ "${1}" = "report" ] ; then
  export KB_SDK_COMPILE_REPORT_FILE=./work/compile_report.json
  make compile
else
  echo Unknown
fi