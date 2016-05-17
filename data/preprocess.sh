#!/bin/bash
# This script preprocesses bitext with Byte Pair Encoding for NMT.
# Executes the following steps:
#     1. Tokenize source and target side of bitext
#     2. Learn BPE-codes for both source and target side
#     3. Encode source and target side using the codes learned
#     4. Shuffle bitext for SGD
#     5. Build source and target dictionaries

if [ "$#" -ne 4 ]; then
    echo ""
    echo "Usage: $0 src trg path_to_data path_to_subword"
    echo ""
    exit 1
fi

# number of merge ops (codes) for bpe
SRC_CODE_SIZE=20000
TRG_CODE_SIZE=20000

# source language (example: fr)
S=$1
# target language (example: en)
T=$2

# path to dl4mt/data
P1=$3

# path to subword NMT scripts (can be downloaded from https://github.com/rsennrich/subword-nmt)
P2=$4


# merge all parallel corpora
./merge.sh $1 $2 $3

# tokenize training and validation data
perl $P1/tokenizer.perl -threads 5 -l $S < ${P1}/all_${S}-${T}.${S} > ${P1}/all_${S}-${T}.${S}.tok
perl $P1/tokenizer.perl -threads 5 -l $T < ${P1}/all_${S}-${T}.${T} > ${P1}/all_${S}-${T}.${T}.tok
perl $P1/tokenizer.perl -threads 5 -l $S < ${P1}/test2011/newstest2011.${S} > ${P1}/newstest2011.${S}.tok
perl $P1/tokenizer.perl -threads 5 -l $T < ${P1}/test2011/newstest2011.${T} > ${P1}/newstest2011.${T}.tok

# BPE
if [ ! -f "${S}.bpe" ]; then
    python $P2/learn_bpe.py -s 20000 < all_${S}-${T}.${S}.tok > ${S}.bpe
fi
if [ ! -f "${T}.bpe" ]; then
    python $P2/learn_bpe.py -s 20000 < all_${S}-${T}.${T}.tok > ${T}.bpe
fi

# utility function to encode a file with bpe
encode () {
    if [ ! -f "$3" ]; then
        python $P2/apply_bpe.py -c $1 < $2 > $3 
    else
        echo "$3 exists, pass"
    fi
}

# apply bpe to training data
encode ${S}.bpe ${P1}/all_${S}-${T}.${S}.tok ${P1}/all_${S}-${T}.${S}.tok.bpe
encode ${T}.bpe ${P1}/all_${S}-${T}.${T}.tok ${P1}/all_${S}-${T}.${T}.tok.bpe
encode ${S}.bpe ${P1}/newstest2011.${S}.tok ${P1}/newstest2011.${S}.tok.bpe
encode ${T}.bpe ${P1}/newstest2011.${T}.tok ${P1}/newstest2011.${T}.tok.bpe

# shuffle 
python $P1/shuffle.py all_${S}-${T}.${S}.tok.bpe all_${S}-${T}.${T}.tok.bpe

# build dictionary
python $P1/build_dictionary.py all_${S}-${T}.${S}.tok.bpe
python $P1/build_dictionary.py all_${S}-${T}.${T}.tok.bpe

