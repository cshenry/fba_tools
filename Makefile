SERVICE = fba_tools
SERVICE_CAPS = fba_tools
SPEC_FILE = fba_tools.spec
URL = https://kbase.us/services/fba_tools
DIR = $(shell pwd)
LIB_DIR = lib
INC = -L/kb/deployment/lib
SCRIPTS_DIR = scripts
TEST_DIR = test
LBIN_DIR = bin
LDATA_DIR = data
TARGET ?= /kb/deployment
EXECUTABLE_SCRIPT_NAME = run_$(SERVICE_CAPS)_async_job.sh
STARTUP_SCRIPT_NAME = start_server.sh
TEST_SCRIPT_NAME = run_tests.sh
KB_RUNTIME ?= /kb/runtime

.PHONY: test

default: compile build-startup-script build-executable-script build-test-script

compile:
	kb-sdk compile $(SPEC_FILE) \
		--out $(LIB_DIR) \
		--plclname $(SERVICE_CAPS)::$(SERVICE_CAPS)Client \
		--jsclname javascript/Client \
		--pyclname $(SERVICE_CAPS).$(SERVICE_CAPS)Client \
		--javasrc src \
		--java \
		--plsrvname $(SERVICE_CAPS)::$(SERVICE_CAPS)Server \
		--plimplname $(SERVICE_CAPS)::$(SERVICE_CAPS)Impl \
		--plpsginame $(SERVICE_CAPS).psgi;
	chmod +x $(SCRIPTS_DIR)/entrypoint.sh

build-executable-script:
	mkdir -p $(LBIN_DIR)
	echo '#!/bin/bash' > $(LBIN_DIR)/$(EXECUTABLE_SCRIPT_NAME)
	echo 'script_dir=$$(dirname "$$(readlink -f "$$0")")' >> $(LBIN_DIR)/$(EXECUTABLE_SCRIPT_NAME)
	echo 'export PERL5LIB=$$script_dir/../$(LIB_DIR):$$PATH:$$PERL5LIB' >> $(LBIN_DIR)/$(EXECUTABLE_SCRIPT_NAME)
	echo 'perl $$script_dir/../$(LIB_DIR)/$(SERVICE_CAPS)/$(SERVICE_CAPS)Server.pm $$1 $$2 $$3' >> $(LBIN_DIR)/$(EXECUTABLE_SCRIPT_NAME)
	chmod +x $(LBIN_DIR)/$(EXECUTABLE_SCRIPT_NAME)

build-startup-script:
	mkdir -p $(LBIN_DIR)
	echo '#!/bin/bash' > $(SCRIPTS_DIR)/$(STARTUP_SCRIPT_NAME)
	echo 'script_dir=$$(dirname "$$(readlink -f "$$0")")' >> $(SCRIPTS_DIR)/$(STARTUP_SCRIPT_NAME)
	echo 'export KB_DEPLOYMENT_CONFIG=$$script_dir/../deploy.cfg' >> $(SCRIPTS_DIR)/$(STARTUP_SCRIPT_NAME)
	echo 'export PERL5LIB=$$script_dir/../$(LIB_DIR):$$PATH:$$PERL5LIB' >> $(SCRIPTS_DIR)/$(STARTUP_SCRIPT_NAME)
	echo 'plackup $$script_dir/../$(LIB_DIR)/$(SERVICE_CAPS).psgi' >> $(SCRIPTS_DIR)/$(STARTUP_SCRIPT_NAME)
	chmod +x $(SCRIPTS_DIR)/$(STARTUP_SCRIPT_NAME)

build-test-script:
	echo '#!/bin/bash' > $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	echo 'script_dir=$$(dirname "$$(readlink -f "$$0")")' >> $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	echo 'export KB_DEPLOYMENT_CONFIG=$$script_dir/../deploy.cfg' >> $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	echo 'export KB_AUTH_TOKEN=`cat /kb/module/work/token`' >> $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	echo 'export PERL5LIB=$$script_dir/../$(LIB_DIR):$$PATH:$$PERL5LIB' >> $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	echo 'cd $$script_dir/../$(TEST_DIR)' >> $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	echo "perl -e 'opendir my \$$dh, \".\"; my @l = grep { /\\\\.pl\$$/ } readdir \$$dh; foreach my \$$s (@l) { print(\"Running \".\$$s.\"\\n\"); system \"perl\", \$$s; }'" >> $(TEST_DIR)/$(TEST_SCRIPT_NAME)
	chmod +x $(TEST_DIR)/$(TEST_SCRIPT_NAME)

deploy-mfatoolkit:
	cp MFAToolkit/bin/libglpk.a $(TARGET)/bin/
	$(MAKE) -C MFAToolkit
	cp MFAToolkit/bin/mfatoolkit $(TARGET)/bin/
	if [ ! -e $(TARGET)/bin/scip ] ; then wget http://bioseed.mcs.anl.gov/~chenry/KbaseFiles/scip ; mv scip $(TARGET)/bin/ ; fi
	if [ ! -d $(TARGET)/etc ] ; then mkdir $(TARGET)/etc ; fi
	if [ ! -d $(TARGET)/etc/MFAToolkit ] ; then mkdir $(TARGET)/etc/MFAToolkit ; fi
	cp MFAToolkit/etc/MFAToolkit/* $(TARGET)/etc/MFAToolkit/
	cp data/classifier.txt $(TARGET)/etc/
	chmod +x $(TARGET)/bin/scip
	chmod +x $(TARGET)/bin/mfatoolkit

test:
	bash $(TEST_DIR)/$(TEST_SCRIPT_NAME)

clean:
	rm -rfv $(LBIN_DIR)
	