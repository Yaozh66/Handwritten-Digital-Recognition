function error= fun2(x,inputnum,hiddennum,outputnum,inputn,outputn,net)
%适应度函数取为分类的误差
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
net.trainParam.showWindow=0;
net.trainParam.show=200;
net.trainParam.epochs=20;%为了减少计算量，优化20代即可
[net,tr]=train(net,inputn,outputn,'useGPU','no');
tInd = tr.testInd;
tstOutputs = net(inputn(:,tInd),'useGPU','no');%不要使用GPU，因为遗传算法有了并行计算
[c,cm] = confusion(outputn(:,tInd),tstOutputs);
error=100*c;
end

