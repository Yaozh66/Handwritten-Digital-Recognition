# Handwritten-Digital-Recognition
by MATLAB R2019a

如果想使用神经网络中的GPU加速，用gpuDevice命令查看是否有matlab支持的gpu，
如果不想使用GPU加速，将代码中的useGPU选项置为no即可

如果想使用遗传算法中的并行加速，建议在启动代码之前运行parpool命令以查看有几个cpu核工作
不想使用并行加速，对应的UseParallel置为no即可

如果想使用代码中的pca或fa降维，请自行到以下网站下载matlab的降维工具箱
http://lvdmaaten.github.io/drtoolbox/