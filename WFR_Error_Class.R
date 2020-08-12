library(data.table)
# Automatically Labeling Error Classes 
obj = get_object(object = "hackathon13/FIG_WFR_LIST_cleaned.csv",bucket = "cdl-hackathon")
obj=rawToChar(obj)
con <- textConnection(obj)
wfr = read.csv(file=con,header = TRUE,sep = ",")
wfr <- data.table(wfr)

library(randomForest)
library(dplyr)

# Train test split with stratification
set.seed(1)
wfr %>%
  group_by(Error_Type_Text) %>%
  filter(length(Error_Type_Text) > 1) %>%
  stratifiedDT("Error_Type_Text", .5, bothSets = TRUE)

train_rows = sample.split(wfr$Error_Type_Text, SplitRatio=0.67)
train = data[train_rows]
test  = data[-train_rows]
model = randomForest(response ~.,data = temp,ntree = 30, sampsize= rep(min(table(temp$response)),3))
