# CVTE_chain_model_finetune
- finetune chain model base on cvte open source model using aishell1 data
- using the open source GMM for frame align 
# Explanation
- cvte supply a chain model trained using more than 2000h audio data
- cvte supply a 3-gram LM model trained with 1000 GB text;
- this project does not need training any GMM series model
- this project support online cmvn, since "apply-cmvn-online" is used during the training and decoding
# Install
- kaldi
# Usage
- bash run_train_ft.sh to prepare the data、train LM(optinal,you can also use the cvte open source HCLG) and finetune chain model
- bash run_test.sh to decode the test data using the finetune model with apply-cmvn-online
# Workflow
- prepare the lexicon if train LM with your own data(optional,you can also use the cvte open source HCLG)
- prepare the train data
- prepare phone sets, questions, L compilation(optinal,you can also use the cvte open source HCLG)
- train LM using kaldi_lm or SRILM(optinal,you can also use the cvte open source HCLG)
- make graph(optinal,you can also use the cvte open source HCLG)
- extract the 40 fbank
- generate speed-perturbed data (for alignment) and use it to align through cvte open source GMM(tri6b)
- get the alignments as lattices
- generate volume-perturbed data (for train)
- prepare config file for finetune such as model、den.fst、phone_lm.fst and tree
- decode the test data use finetune model with apply-cmvn-online
# Result(aishell1 test data) 
- cer 11.10% 
# Reference
- you can cd exp/chain/tdnn_ft/decode_test/scoreing_kaldi to view recognition results and decode cer
- also supply the finetune model,you can download it in the link 链接:https://pan.baidu.com/s/1NvsjV3R7PQy7q7YNITZS8g  密码:su1h
- cvte open source model link http://kaldi-asr.org/models/0002_cvte_chain_model.tar.gz


