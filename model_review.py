import torch
from torchsummary import summary  # 需要安装 torchsummary 包
from model import Generator
import sys

# 定义保存文件路径
save_path = '/home/l611/Projects/ljl/DSAGAN/pretrained_models/DSAStyleganADA.txt'

g_ema = Generator( 1024, 512, 8, channel_multiplier=2 ).to('cuda')
checkpoint = torch.load('/home/l611/Projects/ljl/DSAGAN/pretrained_models/DSAStyleganADA.pt')

g_ema.load_state_dict(checkpoint['g_ema'])
    
# 打开文件进行写入
with open(save_path, 'w') as file:
    # 重定向 print 输出到文件
    sys.stdout = file
    
    # 打印模型结构
    summary(g_ema, input_size=(1, 512))  # 输入尺寸根据你的模型输入维度进行调整
    
    # 打印模型参数
    for name, param in g_ema.named_parameters():
        print(f"{name}: {param.size()}")
        print(param)
        print("=" * 30)

# 恢复 sys.stdout
sys.stdout = sys.__stdout__

# 提示保存完成
print(f"Model summary and weights saved to {save_path}")

