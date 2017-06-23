FROM kbase/kbase:sdkbase.latest
MAINTAINER KBase Developer
# -----------------------------------------

# Insert apt-get instructions here to install
# any required dependencies for your module.

# RUN apt-get update
RUN cpanm -i Config::IniFiles

# -----------------------------------------

RUN apt-get update && apt-get install -y unzip gcc bzip2 ncurses-dev
RUN pip install mpipe
RUN pip install --upgrade requests==2.7.0
RUN pip freeze | grep requests

COPY ./ /kb/module
RUN mkdir -p /kb/module/work
ENV PATH=$PATH:/kb/dev_container/modules/kb_sdk/bin
WORKDIR /kb/module

RUN chmod -R a+rw /kb/module
RUN make

ENTRYPOINT [ "./scripts/entrypoint.sh" ]

CMD [ ]