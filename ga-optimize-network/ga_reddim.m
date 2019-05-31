function ann_data=ga_reddim(ann_data,ann_label,net)
%将维度进行二进制编码，然后进行遗传操作，编码为1的时候代表该维度被选择
%输入为神经网络的数据以及标签还有初始化过的神经网络，返回降维后的数据
    maxgen=50;%遗传50代
    popsize=50;%群体个数为50
    %适应度函数取为利用个体筛选的维度，然后返回预测出来的均方误差
    VFitnessFunction=@(x) fun1(x,ann_data,ann_label,net);
    %设置遗传算法的选项，采用赌轮盘选择，对二进制宜采用单点交叉法以及自适应的变异法
    %使用并行能够加速遗传算法，然后绘制适应度函数图以及距离
    options=optimoptions(@ga,'PopulationType','bitstring','PopulationSize',popsize,'MaxGenerations',maxgen...
    ,'SelectionFcn',@selectionroulette,'PlotFcn',{@gaplotbestf...
 ,@gaplotdistance}   ,'CrossoverFcn',@crossoversinglepoint,'MutationFcn', @mutationadaptfeasible,...
 'UseParallel',true);
    numsum=size(ann_data,1);
    x=ga(VFitnessFunction,numsum,[],[],[],[],[],[],[],[],options);
    %返回个体为1（最优个体为1）的那些维度的数据
    ann_data=ann_data(find(x==1),:);
end

