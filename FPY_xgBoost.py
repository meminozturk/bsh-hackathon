import pandas as pd
import numpy as np
import matplotlib
import matplotlib.pylab as plt 
matplotlib.style.use("ggplot")
import os
from sklearn.model_selection import train_test_split


os.chdir("/Users/memin/Desktop/BSH Hackathon/")

data = pd.read_csv("Input/FPY_Production.csv",error_bad_lines=False,sep = ",")


# Stratification - split data into X and y
data = data.dropna()
data = data.loc[:,['Calendar_day','Material_Plant','QM_production_line','QM_shift','Nav_Material_type_text',
            'Nav_QM.Group_text','IST','Error_Type','Nav_QM.Group','Qty_in_OUn','BW_Amount_in_BUnitM',
            'Cal_year_month ','fpy_rate_material','fpy_rate_group ']]

from sklearn import preprocessing
le = preprocessing.LabelEncoder()

data["Encoded"] = le.fit_transform(data.loc[:,"Error_Type"])
data["Count"] = data.groupby("Error_Type")["IST"].transform("count")
classes = data.loc[:,["Encoded","Error_Type","Count"]].drop_duplicates()
del data["Encoded"], data["Count"]

obj = data.columns[data.dtypes == "object"]

for i in obj:
    data.loc[:,i] = le.fit_transform(data.loc[:,i])

Y = data.loc[:,"Error_Type"]

# To be able to make stratification, we split Y into bins
#bins = np.linspace(0, max(Y)+1,(max(Y)/3000)+1)
#Y_binned = np.digitize(Y, bins)

X = data.drop("Error_Type",axis=1)
seed = 7
test_size = 0.33
data_train, data_test, out_train,out_test= train_test_split(X, Y, test_size=test_size, random_state=seed,stratify=Y)
#del X,Y,seed,test_size,data

# Application of xgBoost
import xgboost as xgb
from sklearn.metrics import accuracy_score

# fit model no training data
model = xgb.XGBClassifier()
model.fit(data_train, out_train)
print(model)

# make predictions for test data
y_pred = model.predict(data_test)
predictions = [round(value) for value in y_pred]

# evaluate predictions
accuracy = accuracy_score(out_test, predictions)
print("Accuracy: %.2f%%" % (accuracy * 100.0))

#Importances
model.feature_importances_
data.drop("value",axis=1,inplace = True)
inLabels = data.columns.tolist()

imp = []
for i in list(range(len(inLabels))):
    if(model.feature_importances_[i]>0.01):
        imp.append(i)
        
importances = model.feature_importances_[imp]
newLabels = data[imp].columns.tolist()

x_pos = list(range(len(newLabels)))
plt.bar(x_pos, importances, align = "center")
plt.grid()
max_y =max(importances)
plt.ylim([0,max_y*1.1])
plt.ylabel("Importance")
plt.xticks(x_pos, newLabels, rotation = 90)
plt.title("Importances of features")
plt.gcf().subplots_adjust(bottom=0.25)
plt.show()