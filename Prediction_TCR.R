obj = get_object(object = "hackathon13/FPY_Production.csv",bucket = "cdl-hackathon")
obj=rawToChar(obj)
con <- textConnection(obj)
fpy_production = read.csv(file=con,header = TRUE,sep = ",")
fpy_production <- data.table(fpy_production)

obj = get_object(object = "hackathon13/WFR_Production.csv",bucket = "cdl-hackathon")
obj=rawToChar(obj)
con <- textConnection(obj)
wfr_production = read.csv(file=con,header = TRUE,sep = ",")
wfr_production <- data.table(wfr_production)

obj = get_object(object = "hackathon13/Repair_Production.csv",bucket = "cdl-hackathon")
obj=rawToChar(obj)
con <- textConnection(obj)
repair_production = read.csv(file=con,header = TRUE,sep = ",")
repair_production <- data.table(repair_production)

str(fpy_production)
colnames(fpy_production)
fpy_production[,Production_Month:=substr(Calendar_day,4,10)]
fpy_production[,Production_Month:=(gsub("(?<![0-9])0+", "", Production_Month, perl = TRUE))]
fpy_production[,Production_Month:=as.character(Production_Month)]
repair_production[,Production_Month:=as.character(Production_Month)]

data <- merge(fpy_production, unique(repair_production[,.(Nav_QM.Group,Nav_QM.Group_TCR,Production_Month,avg_cost_group,avg_life_group)]), by = c("Nav_QM.Group","Production_Month"))

con2 <- rawConnection(raw(0), "r+")
write.csv(data, con2)
#upload the object to S3
aws.s3::put_object(file = rawConnectionValue(con2),bucket = "cdl-hackathon", object = "hackathon13/Prediction_TCR.csv")

### Random Forest ###
str(data)
data[,c("Group2","Error_class_text"):=NULL]
data2 <- copy(data)

### R Cannot deal with factors more than 54 levels 
data2[,c("Calendar_day","Production_Month","Object_part_text","Notification_Item_Short_Text","Notification_Area","Action","Material_Plant"):=NULL]
str(data2)

# We can handle this problem by label encoding

# Train/Test Split
require(caTools)
set.seed(101) 
sample = sample.split(data2$Nav_QM.Group_TCR, SplitRatio = .67)
train = subset(data2, sample == TRUE)
test  = subset(data2, sample == FALSE)

library(randomForest)
model <- randomForest(Nav_QM.Group_TCR~.,data = train,ntree = 20)
prediction <- predict(model,newdata = test)

### Observing the model performance ###
print(model)
importances <- importance(model)
varImpPlot(model)

### MSE ###
round(mean((test$Nav_QM.Group_TCR - prediction)^2),4)

### We implement more robust model in Python in our local. The code is in our directory.

              