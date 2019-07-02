# This Dockerfile uses Docker Multi-Stage Builds
# See https://docs.docker.com/engine/userguide/eng-image/multistage-build/

### Base Image
# Setup up a base image to use in build and runtime images
FROM continuumio/miniconda3 AS base

# Setup workspace environment
RUN apt-get update && apt-get install -y gcc libgmp3-dev libmpfr-dev libmpc-dev python3-dev python3-pip
RUN conda install jupyter notebook

# Intermediate build container
#FROM base as build
WORKDIR /pysonar

# Pysonar image
FROM base AS pysonar

# Setup workdir and copy requirements file
COPY requirements.txt /pysonar

# Install python packages
RUN ["pip3", "install", "numpy", "scipy"]
RUN ["pip3", "install", "-r", "/pysonar/requirements.txt"]

# install pySonar lib
COPY . /pysonar
RUN ["python3", "setup.py", "install"]

# Install nvm with node and npm
ENV NVM_DIR /usr/local/nvm
RUN mkdir -p $NVM_DIR
RUN wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install v8 \
    && nvm alias default v8 \
    && nvm use default

ENV NODE_VERSION 8.16.0
ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# import abi via NPM module
#RUN ["make", "import-abi"]
RUN npm install

# Runtime image
FROM base AS runtime
WORKDIR /notebooks

RUN ["pip3", "install", "jupyter", "notebook"]
COPY notebooks /notebooks
COPY jupyter_notebook_config.py /notebooks/

# Copy artifacts from pysonar image
COPY --from=pysonar /pysonar/ /pysonar/

# Create jupyter notebook workspace
ENV WORKSPACE /workspace
RUN mkdir $WORKSPACE
WORKDIR $WORKSPACE

EXPOSE 8888
CMD ["jupyter", "notebook", "--config=./jupyter_notebook_config.py", "--allow-root"]

