FROM kbase/kbase:sdkbase2.latest
MAINTAINER KBase Developer
# -----------------------------------------

# Insert apt-get instructions here to install
# any required dependencies for your module.

# RUN apt-get update
RUN cpanm -i Config::IniFiles \
    && cpanm -n Devel::Cover

# -----------------------------------------

COPY ./MFAToolkit /kb/module/MFAToolkit
COPY ./Makefile /kb/module/
COPY ./data/classifier.txt /kb/module/data/
WORKDIR /kb/module
RUN make deploy-mfatoolkit
COPY ./ /kb/module
RUN mkdir -p /kb/module/work
ENV PATH=$PATH:/kb/dev_container/modules/kb_sdk/bin

RUN chmod -R a+rw /kb/module
RUN make

ENTRYPOINT [ "./scripts/entrypoint.sh" ]

CMD [ ]