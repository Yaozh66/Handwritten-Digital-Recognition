function error= fun1(x,inputn,outputn,net)
%��Ӧ�����ۺ���������matlab���õ���Ӧ�Ⱥ�����˵��ԽСԽ��
%xΪ���壬inputnΪ���ݣ�outputnΪ��ǩ��netΪ���������
m=find(x==1);%Ѱ��xΪ1��λ�ã�����ѡ����Щά��
inputn=inputn(m,:);
[net,tr]=train(net,inputn,outputn,'useGPU','no');
%���Ԥ��ľ������
tInd = tr.testInd;
tstOutputs = net(inputn(:,tInd),'useGPU','no');%ʹ���Ŵ��㷨�Ĳ��м���ʱ��Ҫ����GPU����
error= perform(net,outputn(:,tInd),tstOutputs)*100;
end

