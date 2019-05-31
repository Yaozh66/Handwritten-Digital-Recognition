function error= fun1(x,inputn,outputn,net)
%适应度评价函数，对于matlab内置的适应度函数来说，越小越好
%x为个体，inputn为数据，outputn为标签，net为传入的数据
m=find(x==1);%寻找x为1的位置，代表选择哪些维度
inputn=inputn(m,:);
[net,tr]=train(net,inputn,outputn,'useGPU','no');
%输出预测的均方误差
tInd = tr.testInd;
tstOutputs = net(inputn(:,tInd),'useGPU','no');%使用遗传算法的并行计算时不要采用GPU加速
error= perform(net,outputn(:,tInd),tstOutputs)*100;
end

