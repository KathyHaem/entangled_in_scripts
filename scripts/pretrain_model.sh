#!/bin/bash
#SBATCH --mem=16g
#SBATCH -p gpu-troja,gpu-ms
#SBATCH -N 2
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:2
#SBATCH --time=6-23
#SBATCH --mail-type=END,FAIL,TIME_LIMIT
#SBATCH --mail-user=limisiewicz@ufal.mff.cuni.cz
#SBATCH --output=/home/limisiewicz/my-luster/entangled-in-scripts/job_outputs/pretrain_model_%j.out


alpha=$1
alpha_train=$2
vocab_size=$3
langs=${@:4:1000}
es_patience=20

cd /home/limisiewicz/my-luster/entangled-in-scripts/entangled_in_scripts/src || exit 1;
source /home/limisiewicz/my-luster/entangled-in-scripts/eis/bin/activate


output_path="/lnet/work/people/limisiewicz/entangled-in-scripts/models/LM/multilingual-tokenization"
config_path="/lnet/work/people/limisiewicz/entangled-in-scripts/models/config/multilingual-tokenization"
data_path="/lnet/express/work/people/limisiewicz/cc100"

seed=1234
pretrain_name="alpha-${alpha}_alpha-train-${alpha_train}_N-${vocab_size}"
model_config="${config_path}/model_alpha-${alpha}_N-${vocab_size}.json"
pt_config="${config_path}/train_config_alpha-${alpha_train}.json"

echo $pretrain_name
echo $model_config
echo $pt_config


python train_mlm.py -o ${output_path} -p $pretrain_name  --model_config_path $model_config --pretrain_config_path $pt_config --load_checkpoint True --seed $seed --data_seed $seed --early_stopping_patience $es_patience

model_dir_path=${output_path}/${pretrain_name}_${seed}


echo "Evaluation"

for lang in ${langs[@]}
do
  python eval.py -e "${data_path}/${lang}/test" -m $model_dir_path -c  $model_config -o ${output_path}/${pretrain_name}_${seed}/${lang}
done

chmod -R 777 $output_path || exit 0;