function error= fun3(x,inputnum,hiddennum,outputnum,inputn,outputn)
%�ú�����������ģ���˻��㷨����Ӧ��ֵ
%x          input     ����
%inputnum   input     �����ڵ���
%outputnum  input     ������ڵ���
%net        input     ����
%inputn     input     ѵ����������
%outputn    input     ѵ���������
%error      output    ������Ӧ��ֵ
%��ȡ
w1=x(1:inputnum*hiddennum);
B1=x(inputnum*hiddennum+1:inputnum*hiddennum+hiddennum);
w2=x(inputnum*hiddennum+hiddennum+1:inputnum*hiddennum+hiddennum+hiddennum*outputnum);
B2=x(inputnum*hiddennum+hiddennum+hiddennum*outputnum+1:inputnum*hiddennum+hiddennum+hiddennum*outputnum+outputnum);
%����Ȩֵ��ֵ
W1=reshape(w1,hiddennum,inputnum);
W2=reshape(w2,outputnum,hiddennum);
B1=reshape(B1,hiddennum,1);
B2=reshape(B2,outputnum,1);
[m n]=size(inputn);
A1=tansig(W1*inputn+repmat(B1,1,n));   %����main�����м������ͬ
A2=softmax(W2*A1+repmat(B2,1,n));      %����main�����м������ͬ  
for i=1:length(inputn)
    out(i)=find(A2(:,i)==max(A2(:,i)));%�ҳ����ж�Ӧ�Ĵ̼�ֵ����λ��
end
[u,v]=find(outputn==1);
label=u';
error=label-out;
accuracy=size(find(error==0),2)/size(label,2);
error=100*(1-accuracy);%��Ӧ�Ⱥ���ȡΪԤ������Ĵ�����
end

