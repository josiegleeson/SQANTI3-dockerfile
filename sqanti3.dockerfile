# Dockerfile for SQANTI3
# https://github.com/ConesaLab/SQANTI3

# adapted from https://github.com/joelnitta/sqanti3-docker/blob/main/Dockerfile

FROM python:3.8.18

LABEL org.opencontainers.image.authors="Josie Gleeson"

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update

#########################
### install miniconda ###
#########################

ENV MINICONDA_VERSION py38_23.9.0-0
ENV CONDA_DIR /miniconda3

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-$MINICONDA_VERSION-Linux-x86_64.sh -O ~/miniconda.sh && \
    chmod +x ~/miniconda.sh && \
    ~/miniconda.sh -b -p $CONDA_DIR && \
    rm ~/miniconda.sh

# make non-activate conda commands available
ENV PATH $CONDA_DIR/bin:$PATH

# make conda activate command available from /bin/bash --login shells
RUN echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> ~/.profile

# make conda activate command available from /bin/bash --interative shells
RUN conda init bash

########################################
### build conda environment: SQANTI3 ###
########################################

# Create /apps for installing software
ENV APPS_HOME /apps
RUN mkdir $APPS_HOME

# Download SQANTI3 and build conda env
WORKDIR $APPS_HOME
ENV APPNAME SQANTI3
ENV ENV_PREFIX $APPNAME.env
RUN git clone https://github.com/josiegleeson/SQANTI3.git && \
  cd $APPNAME && \
  conda update --name base --channel defaults conda && \
  conda env create -f $APPS_HOME/$APPNAME/$APPNAME.conda_env.yml

# Install cDNA_cupcake dependency in SQANTI3 conda environment
WORKDIR $APPS_HOME/$APPNAME/

RUN git clone https://github.com/ConesaLab/cDNA_Cupcake.git

# Need to switch shell from default /sh to /bash so that `source` works
# Need to do pip install scikit-learn so that a compatible version installs
SHELL ["/bin/bash", "-c"]

RUN source $CONDA_DIR/etc/profile.d/conda.sh && \
  conda activate $CONDA_DIR/envs/$ENV_PREFIX && \
  cd cDNA_Cupcake && \
  pip install scikit-learn && \
  python setup.py build && \
  python setup.py install && \
  conda deactivate
SHELL ["/bin/sh", "-c"]

### Make shell scripts to run conda apps in conda environment ###
# e.g., SQANTI3 scripts can be run with `sqanti3_qc.py --help`

# Make python scripts executable 
RUN chmod +x $APPS_HOME/$APPNAME/sqanti3_qc.py && \
  chmod +x $APPS_HOME/$APPNAME/sqanti3_filter.py

# Make wrapper for sqanti3_qc.py
# needs to SQANTI3 conda env and export path to cDNA cupcake
ENV TOOLNAME sqanti3_qc.py
RUN echo '#!/bin/bash' > /usr/local/bin/$TOOLNAME && \
  echo "source $CONDA_DIR/etc/profile.d/conda.sh" >> /usr/local/bin/$TOOLNAME && \
  echo "conda activate $CONDA_DIR/envs/$ENV_PREFIX" >> /usr/local/bin/$TOOLNAME && \
  echo "export PYTHONPATH=$PYTHONPATH:$APPS_HOME/$APPNAME/cDNA_Cupcake/sequence/" >> /usr/local/bin/$TOOLNAME && \
  echo "$APPS_HOME/$APPNAME/$TOOLNAME \"\$@\"" >> /usr/local/bin/$TOOLNAME && \
  chmod 755 /usr/local/bin/$TOOLNAME

# Make wrapper for sqanti3_filter.py
ENV TOOLNAME sqanti3_filter.py
RUN echo '#!/bin/bash' > /usr/local/bin/$TOOLNAME && \
  echo "source $CONDA_DIR/etc/profile.d/conda.sh" >> /usr/local/bin/$TOOLNAME && \
  echo "conda activate $CONDA_DIR/envs/$ENV_PREFIX" >> /usr/local/bin/$TOOLNAME && \
  echo "export PYTHONPATH=$PYTHONPATH:$APPS_HOME/$APPNAME/cDNA_Cupcake/sequence/" >> /usr/local/bin/$TOOLNAME && \
  echo "$APPS_HOME/$APPNAME/$TOOLNAME \"\$@\"" >> /usr/local/bin/$TOOLNAME && \
  chmod 755 /usr/local/bin/$TOOLNAME

WORKDIR /root