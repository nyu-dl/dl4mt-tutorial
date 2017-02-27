#!/usr/bin/python

import argparse
import logging
import os
import tarfile

TRAIN_DATA_URL = 'http://www.statmt.org/europarl/v7/fr-en.tgz'
VALID_DATA_URL = 'http://matrix.statmt.org/test_sets/newstest2011.tgz'

parser = argparse.ArgumentParser(
    description="""
This script donwloads parallel corpora given source and target pair language
indicators. Adapted from,
https://github.com/orhanf/blocks-examples/tree/master/machine_translation
""", formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument("-s", "--source", type=str, help="Source language",
                    default="fr")
parser.add_argument("-t", "--target", type=str, help="Target language",
                    default="en")
parser.add_argument("--source-dev", type=str, default="newstest2011.fr",
                    help="Source language dev filename")
parser.add_argument("--target-dev", type=str, default="newstest2011.en",
                    help="Target language dev filename")
parser.add_argument("--outdir", type=str, default=".",
                    help="Output directory")


def extract_tar_file_to(file_to_extract, extract_into, names_to_look):
    extracted_filenames = []
    try:
        logger.info("Extracting file [{}] into [{}]"
                    .format(file_to_extract, extract_into))
        tar = tarfile.open(file_to_extract, 'r')
        src_trg_files = [ff for ff in tar.getnames()
                         if any([ff.find(nn) > -1 for nn in names_to_look])]
        if not len(src_trg_files):
            raise ValueError("[{}] pair does not exist in the archive!"
                             .format(src_trg_files))
        for item in tar:
            # extract only source-target pair
            if item.name in src_trg_files:
                file_path = os.path.join(extract_into, item.path)
                if not os.path.exists(file_path):
                    logger.info("...extracting [{}] into [{}]"
                                .format(item.name, file_path))
                    tar.extract(item, extract_into)
                else:
                    logger.info("...file exists [{}]".format(file_path))
                extracted_filenames.append(
                    os.path.join(extract_into, item.path))
    except Exception as e:
        logger.error("{}".format(str(e)))
    return extracted_filenames


def main():
    train_data_file = os.path.join(args.outdir, 'train_data.tgz')
    valid_data_file = os.path.join(args.outdir, 'valid_data.tgz')

    # Download europarl v7 and extract it
    extract_tar_file_to(
        train_data_file, os.path.dirname(train_data_file),
        ["{}-{}".format(args.source, args.target)])

    # Download development set and extract it
    extract_tar_file_to(
        valid_data_file, os.path.dirname(valid_data_file),
        [args.source_dev, args.target_dev])


if __name__ == "__main__":

    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger('prepare_data')

    args = parser.parse_args()
    main()
