function error= fun3(x,inputnum,hiddennum,outputnum,inputn,outputn)
%该函数用来计算模拟退火算法的适应度值
%x          input     个体
%inputnum   input     输入层节点数
%outputnum  input     隐含层节点数
%net        input     网络
%inputn     input     训练输入数据
%outputn    input     训练输出数据
%error      output    个体适应度值
%提取
w1=x(1:inputnum*hiddennum);
B1=x(inputnum*hiddennum+1:inputnum*hiddennum+hiddennum);
w2=x(inputnum*hiddennum+hiddennum+1:inputnum*hiddennum+hiddennum+hiddennum*outputnum);
B2=x(inputnum*hiddennum+hiddennum+hiddennum*outputnum+1:inputnum*hiddennum+hiddennum+hiddennum*outputnum+outputnum);
%网络权值赋值
W1=reshape(w1,hiddennum,inputnum);
W2=reshape(w2,outputnum,hiddennum);
B1=reshape(B1,hiddennum,1);
B2=reshape(B2,outputnum,1);
[m n]=size(inputn);
A1=tansig(W1*inputn+repmat(B1,1,n));   %需与main函数中激活函数相同
A2=softmax(W2*A1+repmat(B2,1,n));      %需与main函数中激活函数相同  
for i=1:length(inputn)
    out(i)=find(A2(:,i)==max(A2(:,i)));%找出其中对应的刺激值最大的位置
end
[u,v]=find(outputn==1);
label=u';
error=label-out;
accuracy=size(find(error==0),2)/size(label,2);
error=100*(1-accuracy);%适应度函数取为预测出来的错误率
end

