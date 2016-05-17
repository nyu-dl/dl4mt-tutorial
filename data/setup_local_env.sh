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


# code directory for cloned repositories
CODE_DIR=${HOME}/git/dl4mt-tutorial

# code repository 
CODE_CENTRAL=https://github.com/kyunghyuncho/dl4mt-tutorial

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
python ${CODE_DIR}/data/download_files.py \
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
    python ${CODE_DIR}/data/build_dictionary.py ${DATA_DIR}/europarl-v7.fr-en.fr.tok
    python ${CODE_DIR}/data/build_dictionary.py ${DATA_DIR}/europarl-v7.fr-en.en.tok

    # shuffle traning data
    python ${CODE_DIR}/data/shuffle.py ${DATA_DIR}/europarl-v7.fr-en.en.tok ${DATA_DIR}/europarl-v7.fr-en.fr.tok 
fi

# create model output directory if it does not exist 
if [ ! -d "${MODELS_DIR}" ]; then
    mkdir -p ${MODELS_DIR}
fi

# check if theano is working
python -c "import theano;print 'theano available!'"
