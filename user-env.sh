env_push() {
    eval value=\$$1
    if [[ $value = "" ]]; then
        export $1=$2
    elif [ -d "$2" ]; then
        tmp=$(echo $value | tr ':' '\n' | awk '$0 != "'"$2"'"' | paste -sd: -)
        if [[ $tmp = "" ]]; then export $1=$2; else export $1=$2:$tmp; fi
    fi
}
set_script_dir () {
	pushd . > /dev/null
	SCRIPT_DIR="${BASH_SOURCE[0]}";
	if ([ -h "${SCRIPT_DIR}" ]) then
		while([ -h "${SCRIPT_DIR}" ]) do cd `dirname "$SCRIPT_DIR"`; SCRIPT_PATH=`readlink "${SCRIPT_DIR}"`; done
	fi
	cd `dirname ${SCRIPT_DIR}` > /dev/null
	SCRIPT_DIR=`pwd`;
	popd  > /dev/null
}
ARCHNAME=`perl -V:archname`
ARCHNAME=`echo $ARCHNAME | awk '{ print substr( $0, 11,length($0)-12 ) }'`
set_script_dir
export KB_DEPLOYMENT_CONFIG=$SCRIPT_DIR/localdeploy.cfg
env_push PERL5LIB /kb/runtime/lib/perl5/$ARCHNAME
env_push PERL5LIB /kb/runtime/lib/perl5/$ARCHNAME/auto
env_push PERL5LIB /kb/runtime/lib/perl5
env_push PERL5LIB $SCRIPT_DIR/../KBaseClient/lib
env_push PERL5LIB $SCRIPT_DIR/../KBaseReport/lib
env_push PERL5LIB $SCRIPT_DIR/../handle_service/lib
env_push PERL5LIB $SCRIPT_DIR/lib
export PERL5LIB