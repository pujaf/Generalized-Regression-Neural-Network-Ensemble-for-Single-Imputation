 
clc;
clear;
warning off;
dataset_path='F:\M.Engg\Third Sem\Data Mining\Datasets\Incomplete+Datasets\Ionosphere\';
list= dir([dataset_path,'*.xlsx']);

for counter=1:length(list)
%read xls file

sprintf('%s%d','Loop Number:',counter);
display([dataset_path,list(counter).name]);
[dataset,txt,raw]= xlsread([dataset_path,list(counter).name]);
[orig_dataset,orig_txt,orig_raw]= xlsread('Ionosphere.xlsx');


%listwise deletion

copydataset= dataset;
missing_dataset=copydataset(any(isnan(copydataset),2),:);
copydataset(any(isnan(copydataset),2),:) = [];


%counting missing data and the location of missing data
count= 0;
missing_row=zeros(1,500);
missing_column=zeros(1,500);
pointer=1;

for row=1:size(dataset,1)
    for column=1:size(dataset,2)
        if isnan(dataset(row,column))
            rowstr=num2str(row);
            columnstr=num2str(column);
            
            p=strcat('x','(');          
            q=strcat(p,rowstr);                 
            r=strcat(q,',');                 
            s=strcat(r,columnstr);
            u=strcat(s,')');
           
                              
            missing_row(pointer)=row;
            missing_column(pointer)=column;
            pointer= pointer +1;
           
            
            count= count + 1;
               
        end;
    end;

end;


% segregating the class vector
class_vector=copydataset(:,(size(copydataset,2)));


%data without class vector
copydataset(:,size(copydataset,2))=[];
data_without_class_vector= copydataset;


%min max normalization
max_data_without_class_vector= nanmax(data_without_class_vector);
min_data_without_class_vector=nanmin(data_without_class_vector);
for rows= 1: size(data_without_class_vector,1)
    for columns= 1: size(data_without_class_vector,2)
        data_without_class_vector(rows,columns) = (data_without_class_vector(rows,columns)-min_data_without_class_vector(columns))/(max_data_without_class_vector(columns)-min_data_without_class_vector(columns));
    end;
end;


%copy the matix and indicator variable
copy_data_without_class_vector=data_without_class_vector;
indicator= zeros(size(copy_data_without_class_vector,1),1);
for copyrows=1:size(copy_data_without_class_vector,1)
    for copycolumns=1:size(copy_data_without_class_vector,2)
        if isnan(copy_data_without_class_vector(copyrows,copycolumns))
            indicator(copyrows)=1;
            break;
        else
            indicator(copyrows)=0;
        end;
    end;
end;

copy_data_without_class_vector=[copy_data_without_class_vector indicator];



for k=1:count
   
  nearest_neighour=10;
  [feature_selected,weight]=relieff(copy_data_without_class_vector,class_vector,nearest_neighour);

  data=zeros(size(copy_data_without_class_vector,1),5);
   for index=1:size(copy_data_without_class_vector,1)
    for index2=1:(size(copy_data_without_class_vector,2)-1)
     data(index,index2)=copy_data_without_class_vector(index,feature_selected(index2));
    end;
   end;
  
   
   net=newgrnn(data',class_vector');
   
  for value=1:(size(dataset,2)-1)
       if isnan(dataset(missing_row(k),value))
           dataset(missing_row(k),value)=mean(data_without_class_vector(:,value));
       else 
           continue;
       end;
   end;
   
   if isnan(dataset(missing_row(k),end))
       dataset(missing_row(k),end)=mode(class_vector);
   end;
   
   complete_row=dataset(missing_row(k),:) ;
   
   %remove_class_vector=complete_row(:,(size(complete_row,2)));
   complete_row(:,end)=[];
   
   
   imputed_value=sim(net,complete_row');
   dataset(missing_row(k),missing_column(k))=imputed_value; 
   
end;


new_dataset=dataset;
differnce_imputation=0.5;
final_class_vector=dataset(:,end);
complete_dataset=dataset(:,size(dataset,2)-1);
while (differnce_imputation<0.001)
   initial_imputed_value=new_dataset(missing_row(k),:);
   for k=1:count
       nearest_neighour_new=10;
   [feature_selected_new,weight_new]=relieff(complete_dataset,final_class_vector,nearest_neighour_new);

   for index=1:5
       data1=complete_dataset(:,feature_selected_new(index));
   end;
   
   net1=newgrnn(data1',final_class_vector');
   complete_row_new=new_dataset(missing_row(k),:) ;
    complete_row_new(:,end)=[];
   imputed_value_new=sim(net1,complete_row_new');
   new_dataset(missing_row(k),missing_column(k))=imputed_value_new; 
   differnce_imputation=initial_imputed_value-imputed_value_new;
   end;
    
    
end;


%NRMS calculation
all_val= orig_dataset(:,:).^2;
s=sum(all_val(:));
original_data=sqrt(s);

difference=orig_dataset-new_dataset;
all_val1= difference(:,:).^2;
s1=sum(all_val1(:));
difference_data=sqrt(s1);

NRMS=difference_data/original_data;
display(NRMS);

[a,b,c]=fileparts(list(counter).name);
save([dataset_path,b,'.mat'],'new_dataset');
clear new_dataset;


end;
