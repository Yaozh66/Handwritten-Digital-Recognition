%% 读取图像并使用粗网格法提取特征，然后保存为feature.mat，以后直接加载即可
clc;
clearvars;
close all;
%% 读取图像
root='./data';
img=read_train(root);%img以元胞数组为5000张照片
%% 提取特征
img_feature=feature_lattice(img);
%% 构造标签
class=10;
numberpclass=500;%每个数字有500个样本
ann_label=zeros(class,numberpclass*class);
ann_data=img_feature;
for i=1:class
 for j=numberpclass*(i-1)+1:numberpclass*i
     ann_label(i,j)=1;
 end
end
save feature;
%load feature;
%% PCA降维，使用drtoolbox工具箱
% X=img_feature';为了使用该工具箱需要转置
% [mappedX, mapping] = compute_mapping(X, 'FA', 15);%如果是PCA的话为10就好了
% ann_data=mappedX';%为了使用神经网络，故需转置
%% bp网络初始化参数
% 初始化网络结构
layer=15;
net = patternnet(layer);%隐藏层为15个

%划分训练集，验证集与测试集
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;
net.trainFcn='trainrp';
%net.trainFcn='trainrp';而在创建模式识别神经网络时，默认为trainscg
%trainrp为弹性梯度下降法，可以消除数据太大或太小的误差有四个附加参数
%traingd为梯度下降法
%traingdm，带动量项的梯度下降法附加动量因子参数mc
%traingda，自适应学习率的梯度下降法
%traingdx,带动量项的梯度下降法中附加自适应学习率
%traincgf,Flecher-Reeves共轭梯度法
%traincgp,Polar-Ribere共轭梯度法
%traincgb,Poweel-Beele共轭梯度法
%trainscg，量化共轭梯度法
%trainbfg,BFGS拟牛顿回退法,trainoss可解决该方法的内存问题
%trainlm,Levensberg-Marquatte训练法

%% 遗传算法降维
ann_data=ga_reddim(ann_data,ann_label,net);
%% 先对神经网络进行优化
%计算输入层，隐藏层以及输出层个数
inputnum=size(train_data,1);
hiddennum=layer;
outputnum=size(train_label,1);

%先对网络进行遗传算法，根据分类的误差优化神经网络的权值以及阈值
numsum=inputnum*hiddennum+hiddennum+hiddennum*outputnum+outputnum;%待优化变量个数
lb=repmat(-3,numsum,1);
ub=repmat(3,numsum,1);

tic%计时开始
%配置遗传算法，群体个数为50，遗传代数为50，先对网络进行一次优化以取得初始的权重和阈值，从而避免陷入局部极值
%适应度函数取为用个体的权值和阈值作为网络的初始权值和阈值，然后训练，分类，最后得到的分类误差
%遗传算法采用实数编码法，采用随机均匀分布选择法，加权平均交叉法，自适应变异法，使用并行计算加速遗传算法
popsize=50;
numgen=50;
[net,tr]=train(net,train_data,train_label,'useGPU','yes');
w1=net.iw{1,1};
w2=net.lw{2,1};
b1=net.b{1};
b2=net.b{2};
init=[w1(:)',b1(:)',w2(:)',b2(:)'];
initialmat=repmat(init,popsize,1);
VFitnessFunction = @(x) fun2(x,inputnum,hiddennum,outputnum,train_data,train_label,net);
options=optimoptions(@ga,'PopulationSize',popsize,'MaxGenerations',numgen...
    ,'InitialPopulationMatrix',initialmat,'SelectionFcn',@selectionstochunif,'PlotFcn',{@gaplotbestf...
 ,@gaplotdistance}   ,'CrossoverFcn',@crossoverintermediate,'MutationFcn', @mutationadaptfeasible,...
 'UseParallel',true);
x=ga(VFitnessFunction,numsum,[],[],[],[],lb,ub,[],[],options);
toc
%% BP神经网络创建，训练和测试
%先利用已经优化过的参数对神经网络进行赋值
w1=x(1:inputnum*hiddennum);
B1=x(inputnum*hiddennum+1:inputnum*hiddennum+hiddennum);
w2=x(inputnum*hiddennum+hiddennum+1:inputnum*hiddennum+hiddennum+hiddennum*outputnum);
B2=x(inputnum*hiddennum+hiddennum+hiddennum*outputnum+1:inputnum*hiddennum+hiddennum+hiddennum*outputnum+outputnum);
%网络权值赋值
W1=reshape(w1,hiddennum,inputnum);
W2=reshape(w2,outputnum,hiddennum);
B1=reshape(B1,hiddennum,1);
B2=reshape(B2,outputnum,1);
net.iw{1,1}=W1;%对网络的输入层-隐藏层赋权重
net.lw{2,1}=W2;%对网络的隐藏层-输出层赋权重
net.b{1}=B1;%隐藏层的阈值
net.b{2}=B2;%输出层的阈值

%训练并测试神经网络
[net,tr]=train(net,ann_data,ann_label,'useGPU','yes');
%输出均方误差
tInd = tr.testInd;
tstOutputs = net(ann_data(:,tInd),'useGPU','yes');
tstPerform = perform(net,ann_label(:,tInd),tstOutputs)
% View the Network
view(net)
%绘制神经网络的误差图，正确率图，ROC曲线
figure,plotperform(tr)
figure,plotconfusion(ann_label(:,tInd),tstOutputs)
figure,plotroc(ann_label(:,tInd),tstOutputs)
%% 正确率输出
[c,cm] = confusion(ann_label(:,tInd),tstOutputs);
fprintf('Percentage Correct Classification   : %f%%\n', 100*(1-c));
fprintf('Percentage Incorrect Classification : %f%%\n', 100*c)

