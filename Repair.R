### Repair + Production ###
obj = get_object(object = "hackathon13/FIG_Reparis_All_cleaned.csv",bucket = "cdl-hackathon")
obj=rawToChar(obj)
con <- textConnection(obj)
repair = read.csv(file=con,header = TRUE,sep = ",")
repair <- data.table(repair)

obj = get_object(object = "hackathon13/FIG_Production_Quantity_cleaned.csv",bucket = "cdl-hackathon")
obj=rawToChar(obj)
con <- textConnection(obj)
production = read.csv(file=con,header = TRUE,sep = ",")
production <- data.table(production)

#production[,total_production:=sum(Qty_in_OUn),by = c("Material_Plant","Calendar_day")]
#production[,total_production_group:=sum(Qty_in_OUn),by = c("Nav_QM.Group","Calendar_day")]
#production[,Calendar_day:=as.factor(Calendar_day)]
production[,Production_Month:=substr(Calendar_day,4,10)]
production[,Production_Month:=(gsub("(?<![0-9])0+", "", Production_Month, perl = TRUE))]
#production[,Production_Month:=(sub("^[0]+", "", Production_Month))]
#production[,Production_Month:=lapply(Production_Month, function(y) sub('^0+(?=[1-9])', '', y, perl=TRUE))]
production[,Production_Month:=as.character(Production_Month)]
repair[,Production_Month:=as.character(Production_Month)]
setnames(production,"Material_Plant","Product")

production[,total_group:=sum(Qty_in_OUn),by=.(Nav_QM.Group,Production_Month)]

repair_production <- merge(repair, unique(production[,.(Production_Month,Product,Nav_QM.Group,total_group)]),
                           by = c("Production_Month","Product","Nav_QM.Group"))

# Calculating the TCR Rates
repair_production[,Nav_QM.Group_TCR:=as.numeric(length(Country)),by=.(Production_Month,Nav_QM.Group)]
repair_production[,Nav_QM.Group_TCR:=Nav_QM.Group_TCR/total_group,by=.(Production_Month,Nav_QM.Group)]

repair_production[,EUR:=as.numeric(EUR)]
repair_production[,avg_cost_product:=mean(EUR,na.rm = T), by=.(Product)]
repair_production[,avg_cost_group:=mean(EUR,na.rm = T), by=.(Nav_QM.Group)]

repair_production[,avg_life_product:=mean(Age_of_Appliance,na.rm = T), by=.(Product)]
repair_production[,avg_life_group:=mean(Age_of_Appliance,na.rm = T), by=.(Nav_QM.Group)]


con2 <- rawConnection(raw(0), "r+")
write.csv(repair_production, con2)
#upload the object to S3
aws.s3::put_object(file = rawConnectionValue(con2),bucket = "cdl-hackathon", object = "hackathon13/Repair_Production.csv")

# Detecting Languages From Customer Statements
#library("textcat")
#repair[,Language:=textcat(Customer_Statement)]
