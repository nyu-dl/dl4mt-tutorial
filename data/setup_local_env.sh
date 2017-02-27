#!/bin/bash 
# This script sets up development and data environments for 
# a local machine, copy under your home directory and run.
# Note that, Theano is NOT installed by this script.
# To use Byte Pair Encoding, simply pass -b argument.

BPE=false

while getopts ':b' flag; do
  case "${flag}" in
    b) BPE=true 
       echo "Using Byte Pair Encoding" ;;
    *) error 
       echo ""
       echo "Usage: $0 [-b]"
       echo ""
       exit 1 ;;
  esac
done

if [ -z $PYTHON ]; then
    if [ -n `which python3` ]; then
        export PYTHON=python3
    else
        if [ -n `which python2`]; then
            export PYTHON=python2
        else
            if [ -n `which python`]; then
                export PYTHON=python
            fi
        fi
    fi 
fi

if [ -z $PYTHON ]; then
    echo "Please set PYTHON to a Python interpreter"
    exit 1 
fi

echo "Using $PYTHON"

# code directory for cloned repositories
SCRIPT_DIR=$( dirname "${BASH_SOURCE[0]}" )
CODE_DIR=${SCRIPT_DIR}/..

# code repository 
CODE_CENTRAL=https://github.com/nyu-dl/dl4mt-tutorial

# our input files will reside here
DATA_DIR=${CODE_DIR}/data

# our trained models will be saved here
MODELS_DIR=${HOME}/models


# clone the repository from github into code directory
if [ ! -d "${CODE_DIR}" ]; then
    echo "Cloning central ..."
    mkdir -p ${CODE_DIR}
    git clone ${CODE_CENTRAL} ${CODE_DIR}
fi

# download the europarl v7 and validation sets and extract
if [ ! -f ${DATA_DIR}/train_data.tgz ]; then 
    curl -o ${DATA_DIR}/train_data.tgz http://www.statmt.org/europarl/v7/fr-en.tgz
else
    echo "${DATA_DIR}/train_data.tgz exists"
fi
if [ ! -f ${DATA_DIR}/valid_data.tgz ]; then
    curl -o ${DATA_DIR}/valid_data.tgz http://matrix.statmt.org/test_sets/newstest2011.tgz
else
    echo "${DATA_DIR}/valid_data.tgz exists"
fi
$PYTHON ${CODE_DIR}/data/extract_files.py \
    -s='fr' -t='en' \
    --source-dev=newstest2011.fr \
    --target-dev=newstest2011.en \
    --outdir=${DATA_DIR}

if [ "$BPE" = true ] ; then

    BPE_DIR=${HOME}/codes/subword-nmt
    BPE_CENTRAL=https://github.com/rsennrich/subword-nmt

    # clone subword-nmt repository
    if [ ! -d "${BPE_DIR}" ]; then
        echo "Cloning BPE central ..."
        mkdir -p ${BPE_DIR}
        git clone ${BPE_CENTRAL} ${BPE_DIR}
    fi

    # follow the preprocessing pipeline for BPE
    ./preprocess.sh 'fr' 'en' ${DATA_DIR} ${BPE_DIR}

else

    # tokenize corresponding files
    perl ${CODE_DIR}/data/tokenizer.perl -l 'fr' < ${DATA_DIR}/test2011/newstest2011.fr > ${DATA_DIR}/newstest2011.fr.tok
    perl ${CODE_DIR}/data/tokenizer.perl -l 'en' < ${DATA_DIR}/test2011/newstest2011.en > ${DATA_DIR}/newstest2011.en.tok
    perl ${CODE_DIR}/data/tokenizer.perl -l 'fr' < ${DATA_DIR}/europarl-v7.fr-en.fr > ${DATA_DIR}/europarl-v7.fr-en.fr.tok
    perl ${CODE_DIR}/data/tokenizer.perl -l 'en' < ${DATA_DIR}/europarl-v7.fr-en.en > ${DATA_DIR}/europarl-v7.fr-en.en.tok

    # extract dictionaries
    $PYTHON ${CODE_DIR}/data/build_dictionary.py ${DATA_DIR}/europarl-v7.fr-en.fr.tok
    $PYTHON ${CODE_DIR}/data/build_dictionary.py ${DATA_DIR}/europarl-v7.fr-en.en.tok

    # shuffle traning data
    $PYTHON ${CODE_DIR}/data/shuffle.py ${DATA_DIR}/europarl-v7.fr-en.en.tok ${DATA_DIR}/europarl-v7.fr-en.fr.tok 
fi

# create model output directory if it does not exist 
if [ ! -d "${MODELS_DIR}" ]; then
    mkdir -p ${MODELS_DIR}
fi

# check if theano is working
$PYTHON -c "from __future__ import print_function; import theano; print('theano available!')"
