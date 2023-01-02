#!/bin/bash
#SBATCH --mem=32g
#SBATCH -N 1
#SBATCH --cpus-per-task=2
#SBATCH --time=10:00
#SBATCH --gres=gpu:1
#SBATCH --constraint="gpuram40G|gpuram48G"
#SBATCH -p gpu-troja,gpu-ms
#SBATCH --mail-type=END,FAIL,TIME_LIMIT
#SBATCH --mail-user=balhar.j@gmail.com
#SBATCH --output=/home/balhar/my-luster/entangled-in-scripts/job_outputs/xnli/eval_%j.out

cd /home/$USER/my-luster/entangled-in-scripts/entangled_in_scripts || exit 1;
source /home/$USER/my-luster/entangled-in-scripts/eis/bin/activate

model_type=$1
alpha=$2
train_alpha=$3
vocab_size=$4
lang_src=$5
lang_tgt=$6
seed=$7
probe=$8

if [ "$probe" = "False" ]; then
    eval_name="XNLI_FT"
else
    eval_name="XNLI_PROBE"
fi

input_path="/home/limisiewicz/my-luster/entangled-in-scripts/models/${eval_name}/${model_type}/"
name="alpha-${alpha}_alpha-train-${train_alpha}_N-${vocab_size}"
# add probe to the name
if [ "$probe" = "True" ]; then
    name="${name}_probe"
fi
model_path="$input_path/${name}_${seed}/$lang_src"

# extract tokenizer path from the model_config json file
model_config="/home/limisiewicz/my-luster/entangled-in-scripts/models/config/${model_type}/model_alpha-${alpha}_N-${vocab_size}.json"
tokenizer_path=$(python -c "import json; print(json.load(open('$model_config'))['tokenizer_path'])")

output_path=$model_path

eval_and_save_steps=100

echo start...
echo XNLI
echo ${input_path}
echo ${output_path}
echo ${model_config}
echo ${tokenizer_path}
echo ${name}
echo ${lang_src}
echo ${lang_tgt}

# disable cuda
# export CUDA_VISIBLE_DEVICES=""
# python -m pdb src/finetune_xnli.py \

# TODO: rename the script to run_xnli.py
python src/finetune_xnli.py \
    --model_name_or_path ${model_path} --tokenizer_name ${tokenizer_path} --output_dir ${output_path} --language ${lang_tgt} \
    --max_seq_length 126 --per_device_eval_batch_size 16 --do_predict


chmod -R 770 $output_path || exit 0;

echo end

# Example:
# bash eval_xnli.sh 0.25 0.25 120000 en 333 False