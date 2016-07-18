FROM kbase/kbase:sdkbase.latest
MAINTAINER KBase Developer
# -----------------------------------------

# Insert apt-get instructions here to install
# any required dependencies for your module.

# RUN apt-get update
RUN cpanm -i Config::IniFiles

# Install the SDK (should go away eventually)
RUN \
  . /kb/dev_container/user-env.sh && \
  cd /kb/dev_container/modules && \
  rm -rf jars && \
  git clone https://github.com/kbase/jars && \
  rm -rf kb_sdk && \
  git clone https://github.com/kbase/kb_sdk -b develop && \
  cd /kb/dev_container/modules/jars && \
  make deploy && \
  cd /kb/dev_container/modules/kb_sdk && \
  make && make deploy
RUN \
  . /kb/dev_container/user-env.sh && \
  cd /kb/dev_container/modules && \
  rm -rf data_api && \
  git clone https://github.com/kbase/data_api -b develop && \
  pip install --upgrade /kb/dev_container/modules/data_api

# -----------------------------------------

RUN apt-get update && apt-get install -y unzip gcc bzip2 ncurses-dev
RUN pip install mpipe
COPY ./ /kb/module
RUN mkdir -p /kb/module/work
ENV PATH=$PATH:/kb/dev_container/modules/kb_sdk/bin
WORKDIR /kb/module
RUN pip install --upgrade requests==2.7.0
RUN pip freeze | grep requests

RUN make

ENTRYPOINT [ "./scripts/entrypoint.sh" ]

CMD [ ]