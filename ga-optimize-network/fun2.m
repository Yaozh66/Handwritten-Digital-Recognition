function error= fun2(x,inputnum,hiddennum,outputnum,inputn,outputn,net)
%��Ӧ�Ⱥ���ȡΪ��������
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
net.trainParam.showWindow=0;
net.trainParam.show=200;
net.trainParam.epochs=20;%Ϊ�˼��ټ��������Ż�20������
[net,tr]=train(net,inputn,outputn,'useGPU','no');
tInd = tr.testInd;
tstOutputs = net(inputn(:,tInd),'useGPU','no');%��Ҫʹ��GPU����Ϊ�Ŵ��㷨���˲��м���
[c,cm] = confusion(outputn(:,tInd),tstOutputs);
error=100*c;
end

