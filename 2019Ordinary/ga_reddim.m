function ann_data=ga_reddim(ann_data,ann_label,net)
%��ά�Ƚ��ж����Ʊ��룬Ȼ������Ŵ�����������Ϊ1��ʱ������ά�ȱ�ѡ��
%����Ϊ������������Լ���ǩ���г�ʼ�����������磬���ؽ�ά�������
    maxgen=50;%�Ŵ�50��
    popsize=50;%Ⱥ�����Ϊ50
    %��Ӧ�Ⱥ���ȡΪ���ø���ɸѡ��ά�ȣ�Ȼ�󷵻�Ԥ������ľ������
    VFitnessFunction=@(x) fun1(x,ann_data,ann_label,net);
    %�����Ŵ��㷨��ѡ����ö�����ѡ�񣬶Զ������˲��õ��㽻�淨�Լ�����Ӧ�ı��취
    %ʹ�ò����ܹ������Ŵ��㷨��Ȼ�������Ӧ�Ⱥ���ͼ�Լ�����
    options=optimoptions(@ga,'PopulationType','bitstring','PopulationSize',popsize,'MaxGenerations',maxgen...
    ,'SelectionFcn',@selectionroulette,'PlotFcn',{@gaplotbestf...
 ,@gaplotdistance}   ,'CrossoverFcn',@crossoversinglepoint,'MutationFcn', @mutationadaptfeasible,...
 'UseParallel',true);
    numsum=size(ann_data,1);
    x=ga(VFitnessFunction,numsum,[],[],[],[],[],[],[],[],options);
    %���ظ���Ϊ1�����Ÿ���Ϊ1������Щά�ȵ�����
    ann_data=ann_data(find(x==1),:);
end

