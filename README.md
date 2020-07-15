# CVTE_model_funtune
- funtune chain model base on cvte open source model using aishell1 data
- using the open source GMM for frame align 
# Explanation
- you do not need training any GMM series model
- using apply-cmvn-online instead of apply-cmvn during training and decoding
# Install
- kaldi
# Usage
- bash run_train_ft.sh to prepare the data、train LM(optinal,you can also use the cvte open source HCLG) and funtune chain model
- bash run_test.sh to decode the test data using the funtune model with apply-cmvn-online
# Workflow
- prepare the lexicon if train LM with your own data(optional,you can also use the cvte open source HCLG)
- prepare the train data
- prepare phone sets, questions, L compilation(optinal,you can also use the cvte open source HCLG)
- train LM using kaldi_lm or SRILM(optinal,you can also use the cvte open source HCLG)
- make graph(optinal,you can also use the cvte open source HCLG)
- extract the 40 fbank feat
- generate speed-perturbed data (for alignment) and use it to align through cvte open source GMM(tri6b)
- get the alignments as lattices
- generate volume-perturbed data (for train)
- prepare config file for funtune such as model、den.fst、phone_lm.fst and tree
- decode the test data use funtune model with apply-cmvn-online
# Result(aishell1 test data) 
- cer 11.10% 
# Reference
- you can cd exp/chain/tdnn_ft/decode_test/scoreing_kaldi to view recognition resultssee and cer
- also supply the funtune model,you can download it in the link below
- 链接:https://pan.baidu.com/s/1NvsjV3R7PQy7q7YNITZS8g  密码:su1h


