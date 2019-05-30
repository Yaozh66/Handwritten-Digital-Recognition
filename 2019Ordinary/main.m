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
%% BP�����紴����ѵ���Ͳ���
tic
[net,tr]=train(net,ann_data,ann_label,'useGPU','yes');
toc
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

