import pandas as pd
import numpy as np
import matplotlib
import matplotlib.pylab as plt 
matplotlib.style.use("ggplot")
from sklearn.model_selection import train_test_split
import os
os.chdir("/Users/memin/Desktop/BSH Hackathon/")

data = pd.read_csv("Input/dishcare/production_quality/FIG_FPY_LIST_clenead.csv",sep = ",")
#data.info()

# Stratification - split data into X and y
data = data.dropna()
data = data.loc[:,['QM_production_line','QM_shift','Calendar_day','Nav_Material_type_text',
            'Material_Plant','Nav_QM.Group_text','IST',"Error_Type"]]

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

# Recording labels for plotting importances at the end
inLabels = data_train.columns.tolist()

# To change Numpy ndarray 
out_train = out_train.values
data_train = data_train.values
out_test = out_test.values
data_test = data_test.values

# Applicaiton of Random Forest
from sklearn.ensemble import RandomForestClassifier as rfclass
from sklearn import metrics

model = rfclass(n_estimators = 1000, # The number of trees in the forest.
            criterion = 'gini', # { Regressor: 'mse' | Classifier: 'gini' }
            max_depth = 5, min_samples_split = 2, min_samples_leaf = 1,
            min_weight_fraction_leaf = 0.0, max_features = 'auto',
            max_leaf_nodes = None, bootstrap = True,
            oob_score = True,
            n_jobs = 4, # { 1 | n-cores | -1 == all-cores }
            random_state = None, verbose = 0, warm_start = False)

model = model.fit(data_train, out_train)
predictions = model.predict(data_test)

metrics.confusion_matrix(out_test,predictions) 
metrics.accuracy_score(out_test,predictions) 

np.unique(predictions)

importances = model.feature_importances_                    
#model.oob_score_ # 0.6724                              
#model.oob_prediction_

#forest = pd.DataFrame({"variable":inLabels})
#forest["score"] = importances
#normal = forest.loc[forest.score>0.0001,"variable"].tolist()

# Feature Importance Plot
x_pos = list(range(len(inLabels)))
plt.bar(x_pos, importances, align = "center")
plt.grid()
max_y =max(importances)
plt.ylim([0,max_y*1.1])
plt.ylabel("Importance")
plt.xticks(x_pos, inLabels, rotation = 90)
plt.title("Importances of features")
plt.gcf().subplots_adjust(bottom=0.30)
plt.show()


## Grid Search Cross Validation for Parameter Tuning
#from sklearn.grid_search import GridSearchCV
#param_grid = { 
#    'max_depth': [3,5]
#}
#
#modelCV = GridSearchCV(estimator=model, param_grid=param_grid, cv= 10, n_jobs=4,verbose=10)
#modelCV = modelCV.fit(data_train, out_train)
#modelCV.best_params_
#modelCV.cv_results_
#modelCV.best_score_
#
#
# In case there are hundreds of predictors
#asd = pd.DataFrame({"features":inLabels,"importances":model.feature_importances_})
#imp = []
#for i in list(range(len(inLabels))):
#    if model.feature_importances_[i]>=0.01:
#        print "asd"
#imp.append(i)
#
#importances = model.feature_importances_[imp]
#gcountry.drop("totalview",axis=1,inplace = True)
#newLabels = gcountry[imp].columns.tolist()
#
#x_pos = list(range(len(newLabels)))
#plt.bar(x_pos, importances, align = "center")
#plt.grid()
#max_y =max(importances)
#plt.ylim([0,max_y*1.1])
#plt.ylabel("Importance")
#plt.xticks(x_pos, newLabels, rotation = 90)
#plt.title("Importances of features")
#plt.gcf().subplots_adjust(bottom=0.25)
#plt.show()
