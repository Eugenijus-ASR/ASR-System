export KALDI_ROOT=/home/projects/magistras/kaldi-trunk
[ -f $KALDI_ROOT/tools/env.sh ] && . $KALDI_ROOT/tools/env.sh
export PATH=$PWD/utils/:$KALDI_ROOT/tools/openfst/bin:$PWD:$PATH
[ ! -f $KALDI_ROOT/tools/config/common_path.sh ] && echo >&2 "Error: common_path.sh not found." && return 1
. $KALDI_ROOT/tools/config/common_path.sh
export LC_ALL=C
