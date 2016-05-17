Data pre-processing related scripts and utilities.

#### Setup
Easiest way to setup your environment:

```bash
$ cd ~; mkdir codes; cd codes
$ git clone https://github.com/nyu-dl/dl4mt-tutorial
$ cd dl4mt-tutorial/data
$ ./setup_local_env.sh
```

which will first clone this repository under `~/codes/dl4mt-tutorial`
and then calls the `setup_local_env.sh` script to retrieve example data,
and preprocesses it.

#### Pre-processing
Following steps are executed by `setup_local_env.sh`:
 1. Clone `dl4mt-tutorial` repository (if not cloned already)
 2. Download `europarl-v7.fr-en` (training) and `newstest2011` (development)
 3. Preprocess training and development sets
   * Tokenize using moses tokenizer
   * Shuffle training set for SGD
   * Build source and target dictionaries

#### Pre-processing with subword-units
If you want to use subword-units (eg. [Byte Pair Encoding](https://github.com/rsennrich/subword-nmt)) for source and target tokens, simply call:
```bash
$ ./setup_local_env.sh -b
```
which will replace the third step above, and execute the following steps:
 1. Clone `dl4mt-tutorial` repository (if not cloned already)
 2. Download `europarl-v7.fr-en` (training) and `newstest2011` (development)
 3. Preprocess training and development sets (`preprocess.sh`)
   * Tokenize source and target side of all bitext
   * Learn BPE-codes for both source and target side using training sets
   * Encode source and target side using the learned codes
   * Shuffle training set for SGD
   * Build source and target dictionaries
 
In case you want to preprocess your own data using BPE, you can use `preprocess.sh` script directly.

For the usage and more details, please check the comments in the scripts.
