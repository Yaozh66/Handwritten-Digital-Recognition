function feature = feature_lattice(img)
% ����:�ڵװ��ֵĶ�ֵͼ�������35ά����������
% ======��ȡ������ת��5*7������ʸ��,��ͼ����ÿ10*10�ĵ���л�����ӣ�������ӳ�һ����=====%
%======��ͳ��ÿ��С������ͼ��������ռ�ٷֱ���Ϊ��������====%
lett=zeros(1,35);
feature=zeros(35,length(img));
for i=1:length(img)
%bw2=im2bw(img{i},graythresh(img{i}));%otsu��ֵ�ָgraythreshΪ����ӦѰ����ֵ��im2bwΪ�Ҷ�ͼת��ֵͼ
bw2=imbinarize(img{i});
bw_7050=imresize(bw2,[70,50]);
for cnt=1:7
    for cnt2=1:5
        Atemp=sum(bw_7050(((cnt*10-9):(cnt*10)),((cnt2*10-9):(cnt2*10))));%10*10box
        lett((cnt-1)*5+cnt2)=sum(Atemp);
    end
end
lett=((100-lett)/100);%��Ϊbw_7050Ϊ��ֵͼ����ÿ�����������ĺ�Ϊ100
lett=lett';
feature(:,i)=lett;
end