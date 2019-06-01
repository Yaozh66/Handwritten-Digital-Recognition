# Handwritten-Digital-Recognition
by MATLAB R2019a

by yaozh(2019-5-31)

2019Ordinary文件夹表示使用普通的bp神经网络，ga-optimize-network使用优化过的神经网络

要中途停止其中的遗传算法并进入下一部分的代码，在Genetic Algorithm绘图窗口gui中不断点击stop，直到命令行窗口出现Optimization terminated: stop requested from plot function.

注意本程序中所有遗传算法的适应度函数均为越小越好，适应度越小，个体越优秀

如果想使用神经网络中的GPU加速，用gpuDevice命令查看是否有matlab支持的gpu，
如果不想使用GPU加速，将代码中的useGPU选项置为no即可

如果想使用遗传算法中的并行加速，建议在启动代码之前运行parpool命令以查看有几个cpu核工作
不想使用并行加速，对应的UseParallel置为no即可

如果想使用代码中的pca或fa降维，请自行到以下网站下载matlab的降维工具箱
http://lvdmaaten.github.io/drtoolbox/