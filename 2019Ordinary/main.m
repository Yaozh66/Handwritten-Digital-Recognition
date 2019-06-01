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
%% BP神经网络创建，训练和测试
tic
[net,tr]=train(net,ann_data,ann_label,'useGPU','yes');
toc
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

