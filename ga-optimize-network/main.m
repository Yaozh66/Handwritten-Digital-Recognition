%% ��ȡͼ��ʹ�ô�������ȡ������Ȼ�󱣴�Ϊfeature.mat���Ժ�ֱ�Ӽ��ؼ���
clc;
clearvars;
close all;
%% ��ȡͼ��
root='./data';
img=read_train(root);%img��Ԫ������Ϊ5000����Ƭ
%% ��ȡ����
img_feature=feature_lattice(img);
%% �����ǩ
class=10;
numberpclass=500;%ÿ��������500������
ann_label=zeros(class,numberpclass*class);
ann_data=img_feature;
for i=1:class
 for j=numberpclass*(i-1)+1:numberpclass*i
     ann_label(i,j)=1;
 end
end
save feature;
%load feature;
%% PCA��ά��ʹ��drtoolbox������
% X=img_feature';Ϊ��ʹ�øù�������Ҫת��
% [mappedX, mapping] = compute_mapping(X, 'FA', 15);%�����PCA�Ļ�Ϊ10�ͺ���
% ann_data=mappedX';%Ϊ��ʹ�������磬����ת��
%% bp�����ʼ������
% ��ʼ������ṹ
layer=15;
net = patternnet(layer);%���ز�Ϊ15��

%����ѵ��������֤������Լ�
net.divideParam.trainRatio = 70/100;
net.divideParam.valRatio = 15/100;
net.divideParam.testRatio = 15/100;
net.trainFcn='trainrp';
%net.trainFcn='trainrp';���ڴ���ģʽʶ��������ʱ��Ĭ��Ϊtrainscg
%trainrpΪ�����ݶ��½�����������������̫���̫С��������ĸ����Ӳ���
%traingdΪ�ݶ��½���
%traingdm������������ݶ��½������Ӷ������Ӳ���mc
%traingda������Ӧѧϰ�ʵ��ݶ��½���
%traingdx,����������ݶ��½����и�������Ӧѧϰ��
%traincgf,Flecher-Reeves�����ݶȷ�
%traincgp,Polar-Ribere�����ݶȷ�
%traincgb,Poweel-Beele�����ݶȷ�
%trainscg�����������ݶȷ�
%trainbfg,BFGS��ţ�ٻ��˷�,trainoss�ɽ���÷������ڴ�����
%trainlm,Levensberg-Marquatteѵ����

%% �Ŵ��㷨��ά
ann_data=ga_reddim(ann_data,ann_label,net);
%% �ȶ�����������Ż�
%��������㣬���ز��Լ���������
inputnum=size(train_data,1);
hiddennum=layer;
outputnum=size(train_label,1);

%�ȶ���������Ŵ��㷨�����ݷ��������Ż��������Ȩֵ�Լ���ֵ
numsum=inputnum*hiddennum+hiddennum+hiddennum*outputnum+outputnum;%���Ż���������
lb=repmat(-3,numsum,1);
ub=repmat(3,numsum,1);

tic%��ʱ��ʼ
%�����Ŵ��㷨��Ⱥ�����Ϊ50���Ŵ�����Ϊ50���ȶ��������һ���Ż���ȡ�ó�ʼ��Ȩ�غ���ֵ���Ӷ���������ֲ���ֵ
%��Ӧ�Ⱥ���ȡΪ�ø����Ȩֵ����ֵ��Ϊ����ĳ�ʼȨֵ����ֵ��Ȼ��ѵ�������࣬���õ��ķ������
%�Ŵ��㷨����ʵ�����뷨������������ȷֲ�ѡ�񷨣���Ȩƽ�����淨������Ӧ���취��ʹ�ò��м�������Ŵ��㷨
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
%% BP�����紴����ѵ���Ͳ���
%�������Ѿ��Ż����Ĳ�������������и�ֵ
w1=x(1:inputnum*hiddennum);
B1=x(inputnum*hiddennum+1:inputnum*hiddennum+hiddennum);
w2=x(inputnum*hiddennum+hiddennum+1:inputnum*hiddennum+hiddennum+hiddennum*outputnum);
B2=x(inputnum*hiddennum+hiddennum+hiddennum*outputnum+1:inputnum*hiddennum+hiddennum+hiddennum*outputnum+outputnum);
%����Ȩֵ��ֵ
W1=reshape(w1,hiddennum,inputnum);
W2=reshape(w2,outputnum,hiddennum);
B1=reshape(B1,hiddennum,1);
B2=reshape(B2,outputnum,1);
net.iw{1,1}=W1;%������������-���ز㸳Ȩ��
net.lw{2,1}=W2;%����������ز�-����㸳Ȩ��
net.b{1}=B1;%���ز����ֵ
net.b{2}=B2;%��������ֵ

%ѵ��������������
[net,tr]=train(net,ann_data,ann_label,'useGPU','yes');
%����������
tInd = tr.testInd;
tstOutputs = net(ann_data(:,tInd),'useGPU','yes');
tstPerform = perform(net,ann_label(:,tInd),tstOutputs)
% View the Network
view(net)
%��������������ͼ����ȷ��ͼ��ROC����
figure,plotperform(tr)
figure,plotconfusion(ann_label(:,tInd),tstOutputs)
figure,plotroc(ann_label(:,tInd),tstOutputs)
%% ��ȷ�����
[c,cm] = confusion(ann_label(:,tInd),tstOutputs);
fprintf('Percentage Correct Classification   : %f%%\n', 100*(1-c));
fprintf('Percentage Incorrect Classification : %f%%\n', 100*c)

