# !/bin/bash
# This script uses weight transfer as a transfer learning method to transfer
# already trained neural net model on aishell2 to a finetune data set.
. ./path.sh
. ./cmd.sh
# training options
frames_per_eg=150,110,90
chunk_left_context=0
chunk_right_context=0
#frames_per_eg=8
srand=0
remove_egs=true
common_egs_dir=
xent_regularize=0.1

data_set=train
data_dir=data/${data_set}
ali_dir=exp/${data_set}_ali
lat_dir=exp/${data_set}_lat

src_dir=exp/chain/tdnn
dir=${src_dir}_ft
init_dir=exp/chain/tdnn
gmm_dir=exp/chain/tri6b
tree_dir=exp/chain/tri6b_tree

stage=0
train_stage=-4
nj=8

if [ $stage -le 0 ]; then
  echo "$0: preparing directory for low-resolution speed-perturbed data (for alignment)"
  utils/data/perturb_data_dir_speed_3way.sh \
    data/${data_set} data/${data_set}_sp
  echo "$0: making MFCC features for low-resolution speed-perturbed data (needed for alignments)"
   steps/make_mfcc_pitch.sh --nj $nj \
    --cmd "$train_cmd" data/${data_set}_sp
  steps/compute_cmvn_stats.sh data/${data_set}_sp
  echo "$0: fixing input data-dir to remove nonexistent features, in case some "
  echo ".. speed-perturbed segments were too short."
  utils/fix_data_dir.sh data/${data_set}_sp
  steps/align_fmllr.sh --cmd "$train_cmd" --nj ${nj} data/${data_set}_sp data/lang $gmm_dir ${ali_dir}
fi

if [ $stage -le 1 ]; then
  # Get the alignments as lattices (gives the LF-MMI training more freedom).
  # use the same num-jobs as the alignments
  nj=$(cat $ali_dir/num_jobs) || exit 1;
  steps/align_fmllr_lats.sh --nj $nj --cmd "$train_cmd" data/${data_set}_sp \
    data/lang $gmm_dir $lat_dir
  rm $lat_dir/fsts.*.gz # save space
fi


if [ $stage -le 2 ]; then
  # extract mfcc_hires for AM finetuning
  utils/copy_data_dir.sh ${data_dir}_sp ${data_dir}_sp_fbk
  rm -f ${data_dir}_sp_fbk/{cmvn.scp,feats.scp}
  utils/data/perturb_data_dir_volume.sh ${data_dir}_sp_fbk || exit 1;
  steps/make_fbank.sh \
    --cmd "$train_cmd" --nj $nj --fbank-config conf/fbank.conf \
    ${data_dir}_sp_fbk
  steps/compute_cmvn_stats.sh ${data_dir}_sp_fbk
  utils/fix_data_dir.sh ${data_dir}_sp_fbk
fi

if [ $stage -le 3 ]; then
    echo Prepare the configuration file for model training from cvte model file tdnn
    if [ ! -f $dir ]; then
     cp -r $init_dir $dir
     mv $dir/final.mdl $dir/init.mdl
    fi
fi

if [ $stage -le 4 ]; then
  if [[ $(hostname -f) == *.clsp.jhu.edu ]] && [ ! -d $dir/egs/storage ]; then
    utils/create_split_dir.pl \
     /export/b0{3,4,5,6}/$USER/kaldi-data/egs/wsj-$(date +'%m_%d_%H_%M')/s5/$dir/egs/storage $dir/egs/storage
     fi
    steps/nnet3/chain/train.py --stage=$train_stage \
    --cmd="$decode_cmd" \
    --trainer.input-model=$dir/init.mdl \
    --feat.cmvn-opts="--norm-means=false --norm-vars=false" \
    --chain.xent-regularize $xent_regularize \
    --chain.leaky-hmm-coefficient=0.1 \
    --chain.l2-regularize=0.00005 \
    --chain.apply-deriv-weights=false \
    --chain.lm-opts="--num-extra-lm-states=2000" \
    --trainer.srand=$srand \
    --trainer.max-param-change=2.0 \
    --trainer.num-epochs=6 \
    --trainer.frames-per-iter=1500000 \
    --trainer.optimization.num-jobs-initial=2 \
    --trainer.optimization.num-jobs-final=3 \
    --trainer.optimization.initial-effective-lrate=0.0001 \
    --trainer.optimization.final-effective-lrate=0.00001 \
    --trainer.optimization.shrink-value=1.0 \
    --trainer.num-chunk-per-minibatch=128 \
    --trainer.optimization.momentum=0.0 \
    --egs.chunk-width=$frames_per_eg \
    --egs.chunk-left-context-initial=0 \
    --egs.chunk-right-context-final=0 \
    --egs.dir="$common_egs_dir" \
    --egs.opts="--frames-overlap-per-eg 0" \
    --cleanup.remove-egs=$remove_egs \
    --use-gpu=wait \
    --reporting.email="$reporting_email" \
    --feat-dir=${data_dir}_sp_fbk \
    --tree-dir=$tree_dir \
    --lat-dir=$lat_dir \
    --dir=$dir  || exit 1;
fi
exit 0;
