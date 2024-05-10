# DSAGAN

代码工程位置（161） /home/k611/data3/ljl/DSAGAN/

## 数据处理

标签



## 生成

#### 训练

```shell
```



#### 生成样例（根据标签



#### 生成图片、视频、3D模型

根据潜码生成视频

```shell
python scripts/gen_videos.py --outdir=RESULT_PATH --trunc=0.7 --seeds=134 --grid=2x2 --network=EG3D_MODEL_PATH --num-keyframes=2 --v_num=3 --v_range=32
```





## 反演:  编码器 + 优化



#### 编码器训练

```shell
python scripts/train_psp.py --exp_dir=RESULT_PATH --device=cuda:0 --n_styles=14 --batch_size=1 --test_batch_size=1 --workers=8 --test_workers=8 --val_interval=2500 --save_interval=5000 --checkpoint_path=COUNTINE_TRAIN_MODEL_PATH
```



#### 编码器推理（生成图片、潜码

```shell
# 新训练模型
python scripts/inference_psp.py --exp_dir=RESULT_PATH --checkpoint_path=ENCODER_MODEL_PATH --data_path=DATA_PATH --test_batch_size=1 --test_workers=4

# 旧训练模型
python scripts/inference.py --exp_dir=RESULT_PATH --checkpoint_path=ENCODER_MODEL_PATH --data_path=DATA_PATH --test_batch_size=1 --test_workers=4
```

常用编码器模型

```shell
# 新训练 （--checkpoint_path=ENCODER_MODEL_PATH）
/home/k611/data3/ljl/DSAPretrainedModels/iteration_1325000.pt
# 配套eg3d （在 /DSAGAN/configs/paths_config.py 中更改eg3d_dsa）
/home/k611/data3/ljl/DSAGAN/pretrained_models/eg3d_dsa_2444.pth
/home/k611/data3/ljl/DSAPretrainedModels/network-snapshot-002444.pkl

# 旧训练 （--checkpoint_path=ENCODER_MODEL_PATH）
/home/k611/data3/ljl/DSAPretrainedModels/iteration_1605000.pt
# 配套eg3d （在 /DSAGAN/configs/paths_config.py 中更改eg3d_dsa）
/home/k611/data3/ljl/DSAGAN/pretrained_models/eg3d_dsa_1432.pth
/home/k611/data3/ljl/DSAPretrainedModels/network-snapshot-001432.pkl
```



#### 优化命令



## 多中心数据

cyclegan

训练



推理





## 演示

生成360度图片集合

