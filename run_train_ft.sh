#!/bin/bash

# Copyright 2017 Beijing Shell Shell Tech. Co. Ltd. (Authors: Hui Bu)
#           2017 Jiayu Du
#           2017 Xingyu Na
#           2017 Bengu Wu
#           2017 Hao Zheng
# Apache 2.0

# This is a shell script, but it's recommended that you run the commands one by
# one by copying and pasting into the shell.
# Caution: some of the graph creation steps use quite a bit of memory, so you
# should run this on a machine that has sufficient memory.

#需要建立路径，存放下载的数据
data=data
data_url=www.openslr.org/resources/33

. ./cmd.sh

#利用download_and_untar.sh脚本下载两个文件 data_shell 和resource_shell
# ||逻辑或，当其之前的语句执行成功返回0，则不会执行其后的语句，否则返回1表示语句执行错误
# local/download_and_untar.sh $data $data_url data_aishell || exit 1;
# local/download_and_untar.sh $data $data_url resource_aishell || exit 1;

# Lexicon Preparation,
 local/prepare_dict.sh data/local/dict || exit 1;

# Data Preparation,
 local/aishell_data_prep.sh $data/wav $data/wav || exit 1;

# Phone Sets, questions, L compilation
 utils/prepare_lang.sh --position-dependent-phones false data/local/dict \
    "<SPOKEN_NOISE>" data/local/lang data/lang || exit 1;

# LM training
# local/aishell_train_lms.sh || exit 1;
# LM training SRILM
  #生成计数文件 
  mkdir data/local/lm/
  ngram-count -text data/train/text_lm -order 4 -write data/local/lm/xgn_count 
  #生成ARPA LM 
  ngram-count -read data/local/lm/xgn_count -order 4 -lm data/local/lm/xgn_lm -interpolate -kndiscount 
  gzip data/local/lm/xgn_lm


# G compilation, check LG composition
  utils/format_lm.sh data/lang data/local/lm/xgn_lm.gz \
    data/local/dict/lexicon.txt data/lang_test || exit 1;

  utils/mkgraph.sh data/lang_test exp/chain/tdnn_ft exp/chain/tdnn_ft/graph || exit 1;

# Now make MFCC plus pitch features.
# mfccdir should be some place with a largish disk where you
# want to store MFCC features.
# fbankdir=fbank
 for x in train ; do
  mkdir -p fbank/$x

  # compute fbank without pitch
  steps/make_fbank.sh --nj 1 --cmd "run.pl" data/$x exp/make_fbank/$x fbank/$x || exit 1;
  # compute cmvn
  steps/compute_cmvn_stats.sh data/$x exp/fbank_cmvn/$x fbank/$x || exit 1;
  utils/fix_data_dir.sh data/$x || exit 1;
# done


# nnet3
local/chain/run_cvte_ft.sh

exit 0;
