#!/bin/bash

. ./cmd.sh
. ./path.sh

# step 1: generate fbank features
obj_dir=data

for x in test; do
  # rm fbank/$x
  mkdir -p fbank/$x

  # compute fbank without pitch
  steps/make_fbank.sh --nj 1 --cmd "run.pl" $obj_dir/$x exp/make_fbank/$x fbank/$x || exit 1;
  # compute cmvn
  steps/compute_cmvn_stats.sh $obj_dir/$x exp/fbank_cmvn/$x fbank/$x || exit 1;
done

# #step 2: offline-decoding
test_data=data/test
dir=exp/chain/tdnn_ft


steps/nnet3/decode_online.sh --acwt 1.0 --post-decode-acwt 10.0 \
  --nj 1 --num-threads 1 \
  --cmd "$decode_cmd" --iter final \
  --frames-per-chunk 50 \
  $dir/graph $test_data $dir/decode_test

# # note: the model is trained using "apply-cmvn-online",
# # so you can modify the corresponding code in steps/nnet3/decode.sh to obtain the best performance,
# # but if you directly steps/nnet3/decode.sh, 
# # the performance is also good, but a little poor than the "apply-cmvn-online" method.
# getting results (see RESULTS file)
for x in exp/chain/tdnn_ft/decode_test; do [ -d $x ] && grep WER $x/cer_* | utils/best_wer.sh; done 2>/dev/null
for x in exp/chain/tdnn_ft/decode_test; do [ -d $x ] && grep WER $x/wer_* | utils/best_wer.sh; done 2>/dev/null
