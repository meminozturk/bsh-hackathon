#SET CREDENTIALS TO SYSTEM ENVIRONMENT
Sys.setenv("AWS_ACCESS_KEY_ID" = "AKIAJV66NWWWUG7E5G4A",
           "AWS_SECRET_ACCESS_KEY" = "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",
           "AWS_DEFAULT_REGION" = "eu-central-1")

library("aws.s3")

### FPY ###
obj = get_object(object = "hackathon_data/csv/dishcare/production_quality/FIG_FPY_LIST.csv",bucket = "cdl-hackathon")
obj=rawToChar(obj)
con <- textConnection(obj)
fpy = read.csv(file=con,header = TRUE,sep = ";")
fpy <- data.table(fpy)
summary(fpy)
str(fpy)
# Remove duplicates if there is 
fpy = unique(fpy)

# Removing initials in QM_Serial Number
library("stringi")
fpy[,QM_production_line:=stri_sub(QM_production_line, 6)]
fpy[,QM_shift:=stri_sub(QM_shift, 6)]
fpy[,QM_serial_number:=stri_sub(QM_serial_number, 6)]
fpy[,Material_Plant:=stri_sub(Material_Plant, 6)]

# Removing unnecessary variables
# Analyzing all variable pairs by hand 
if(1==0){
  View(unique(fpy[,.(Material_Plant,Material_Plant_text)]))
  View(unique(fpy[,.(Material_Plant,Material_Plant_text)]))
  View(unique(fpy[,.(Code_group.Object_Part,Code_group.Object_Part_text)]))
  View(unique(fpy[,.(Nav_QM.Group,Nav_QM.Group_text)]))
  View(unique(fpy[,.(Notification_Item_Short_Text,Error_Description)]))
  View(unique(fpy[,.(Error_Type,Error_Type_Text)]))
}

# There are differences btw. levels of material plant and text
fpy[,Material_Plant:=as.factor(Material_Plant)]

# Code_group.Object_Part has 56 Levels and Code_group.Object_Part_ text has 46 levels; 
# we will use Code_group.Object_Part_text for simplification
# There is relationship btw. Notification and Error description, Error_description is very noisy
# Cleaning Object_part_text; there are duplicates because of typos
# There are NAs in error types
# Action can be refined in OpenRefine

fpy[,c("Error_class","Code_group.Problem","Code_group.Object_Part","Activity","Object_part","Nav_Material_type",
      "Material_Plant_text","QM_Serial_Number_2","Error_Description"):=NULL]

source("Functions.R")
fpy <- extract_group(fpy)

con2 <- rawConnection(raw(0), "r+")
write.csv(fpy, con2)
#upload the object to S3
aws.s3::put_object(file = rawConnectionValue(con2),bucket = "cdl-hackathon", object = "hackathon13/FIG_FPY_LIST_cleaned.csv")


### WFR List ###
obj = get_object(object = "hackathon_data/csv/dishcare/production_quality/FIG_WFR_LIST.csv",bucket = "cdl-hackathon")
obj=rawToChar(obj)
con <- textConnection(obj)
wfr = read.csv(file=con,header = TRUE,sep = ";")
wfr <- data.table(wfr)
summary(wfr)
str(wfr)
wfr <- unique(wfr)

# Removing initials in QM_Serial Number
wfr[,QM_production.line:=stri_sub(QM_production.line, 6)]
wfr[,QM_serial_number:=stri_sub(QM_serial_number, 6)]
wfr[,Material_Plant:=stri_sub(Material_Plant, 6)]

# Removing Unnecessary Columns
wfr[,c("Code_group","Code_group2","Nav_Material_type","Problem_frequency","Notification_text","Nav_QM.Group"):=NULL]

setnames(wfr, "Code_group_text", "Code_group.Problem_text")
setnames(wfr, "Code_group2_text", "Code_group.Object_Part_text")
setnames(wfr, "Notification_Item_Part", "Notification_Area")

wfr[,length(Calendar_day),by=.(Error_class_text)]
wfr <- extract_group(wfr)

con2 <- rawConnection(raw(0), "r+")
write.csv(wfr, con2)
#upload the object to S3
aws.s3::put_object(file = rawConnectionValue(con2),bucket = "cdl-hackathon", object = "hackathon13/FIG_WFR_LIST_cleaned.csv")

# After Changing invalid column names; adding shifts 
obj = get_object(object = "hackathon13/WFR_IncludingShiftDetail.csv",bucket = "cdl-hackathon")
obj = rawToChar(obj)
con <- textConnection(obj)
wfr_shift = read.csv(file=con,header = T,sep = ";")
wfr_shift <- data.table(wfr_shift)
wfr[,QM_serial_number:=as.numeric(QM_serial_number)]
asd <- merge(wfr,wfr_shift,by = "QM_serial_number",all.x = T)
# Most of the serial numbers are empty

### Repair ###
repair_all <- c("hackathon_data/csv/dishcare/repair/FIG_Reparis_01-02_2014.csv",
"hackathon_data/csv/dishcare/repair/FIG_Reparis_03-04_2014.csv",
"hackathon_data/csv/dishcare/repair/FIG_Reparis_05-06_2014.csv",
"hackathon_data/csv/dishcare/repair/FIG_Reparis_07-08_2014.csv",
"hackathon_data/csv/dishcare/repair/FIG_Reparis_09-10_2014.csv",
"hackathon_data/csv/dishcare/repair/FIG_Reparis_11-12_2014.csv",
"hackathon_data/csv/dishcare/repair/FIG_Reparis_01-03_2015.csv", 
"hackathon_data/csv/dishcare/repair/FIG_Reparis_04-06_2015.csv", 
"hackathon_data/csv/dishcare/repair/FIG_Repairs_07-12_2015.csv", 
"hackathon_data/csv/dishcare/repair/FIG_Repairs_01-12.2016.csv",
"hackathon_data/csv/dishcare/repair/FIG_Reparis_01-03_2017.csv")
repair = data.table()
for(i in repair_all){
  obj = get_object(object = i,bucket = "cdl-hackathon")
  obj=rawToChar(obj)
  con <- textConnection(obj)
  asd = read.csv(file=con,header = TRUE,sep = ";")
  asd <- data.table(asd)
  repair <- rbind(repair,asd)
}

repair <- unique(repair)
summary(repair)
str(repair)
repair <- unique(repair)

setnames(repair, "QM_Product_Group", "Nav_QM.Group")
setnames(repair, "QM_Product_Group_text", "Nav_QM.Group_text")

repair <- extract_group(repair)
repair[,c("Fault_Code_FA_text"):=NULL]


con2 <- rawConnection(raw(0), "r+")
write.csv(repair, con2)
#upload the object to S3
aws.s3::put_object(file = rawConnectionValue(con2),bucket = "cdl-hackathon", object = "hackathon13/FIG_Repairs_All_cleaned.csv")

### BOM ###
obj = get_object(object = "hackathon_data/csv/dishcare/bom/BOM_5324.csv",bucket = "cdl-hackathon")
obj=rawToChar(obj)
con <- textConnection(obj)
bom = read.csv(file=con,header = TRUE,sep = ";")
bom <- data.table(bom)
summary(bom)
str(bom)

# Deleting unnecessary variables 
#bom[,c("Source_System","Plant"):=NULL]


### Spare Parts & Material Assignment ###
obj = get_object(object = "hackathon_data/csv/dishcare/bom/FIG_SparePart&Material Assignment.csv",bucket = "cdl-hackathon")
obj=rawToChar(obj)
con <- textConnection(obj)
spare = read.csv(file=con,header = TRUE,sep = ";")
spare <- data.table(spare)
summary(spare)
str(spare)

### Group Hierarchy ### There is a problem
obj = get_object(object = "hackhaton13/Product_Group_Hierarchy.csv",bucket = "cdl-hackathon")
obj=rawToChar(obj)
con <- textConnection(obj)
hierarchy = read.csv(file=con,header = TRUE,sep = ",")
hierarchy <- data.table(hierarchy)
summary(hierarchy)
str(hierarchy)

### QM_Partstructure ###
obj = get_object(object = "hackathon_data/csv/dishcare/hierarchy/FIG_QM_PARTSTRUCTURE.csv",bucket = "cdl-hackathon")
obj=rawToChar(obj)
con <- textConnection(obj)
partstructure = read.csv(file=con,header = TRUE,sep = ";")
partstructure <- data.table(partstructure)
summary(partstructure)
str(partstructure)

### Production Quantity ###
obj = get_object(object = "hackathon_data/csv/dishcare/production_quantity/FIG_Production_Quantity_2014-03.2017.csv",bucket = "cdl-hackathon")
obj=rawToChar(obj)
con <- textConnection(obj)
production = read.csv(file=con,header = TRUE,sep = ";")
production <- data.table(production)
summary(production)
str(production)

# They are not the same, whats the difference
production[,QM_production_line:=stri_sub(QM_production_line, 6)]
production[,Material_Plant:=stri_sub(Material_Plant, 6)]

production[,c("Nav_Material_type"):=NULL]
production[,Qty_in_OUn:=as.numeric(Qty_in_OUn)]
production[,BW_Amount_in_BUnitM:=as.numeric(BW_Amount_in_BUnitM)]

con2 <- rawConnection(raw(0), "r+")
write.csv(production, con2)
#upload the object to S3
aws.s3::put_object(file = rawConnectionValue(con2),bucket = "cdl-hackathon", object = "hackathon13/FIG_Production_Quantity_cleaned.csv")


#write to an in-memory raw connection
con2 <- rawConnection(raw(0), "r+")
write.csv(data, con2)

#upload the object to S3
aws.s3::put_object(file = rawConnectionValue(con2),bucket = "cdl-hackathon", object = "hackathon13/test_ba_wo_spark.csv")

#close the connection
close(con2)
