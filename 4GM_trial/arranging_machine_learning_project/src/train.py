# coding: utf-8

import argparse
import os

import joblib
import pandas as pd

from sklearn import metrics
from sklearn import tree

import model_dispatcher
import config

def run(df, fold, model):
    # training data is where kfold is not equal to provided fold.
    # also, note that we reset the index
    df_train = df[df['kfold'] != fold].reset_index(drop=True)

    # validation data is where kfold is equal to provided fold.
    df_valid = df[df['kfold'] == fold].reset_index(drop=True)

    # drop the label column from dataframe and convert it to
    # a numpy array by using .values.
    # target is label column in the dataframe.
    X_train = df_train.drop('label', axis=1).values
    y_train = df_train['label'].values

    # similarly, for validation set.
    X_valid = df_valid.drop('label', axis=1).values
    y_valid = df_valid['label'].values

    # initialize simple decision tree classifier from sklearn
    clf =  model_dispatcher.models[model] # tree.DecisionTreeClassifier()

    # fit
    clf.fit(X_train, y_train)
    
    # create predictions for validation samples
    preds = clf.predict(X_valid)

    # calculate and print accuracy
    accuracy = metrics.accuracy_score(y_valid, preds)
    print(f'Fold = {fold}, Accuracy = {accuracy}')

    # save the model
    # joblib.dump(clf, f'../models/Decision_tree_model_fold_{fold}.bin')
    return clf

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '--fold',
        type=int
    )
    parser.add_argument(
        '--model',
        type=str
    )
    args = parser.parse_args()
    df = pd.read_csv("./input/mnist_train_folds.csv")
    lst = [0,1,2,3,4]
    #for ls in lst:
    print(f'model running... {args.model} in fold {args.fold + 1}')
    tmp_clf = run(df, fold=args.fold, model=args.model)
    joblib.dump(tmp_clf, f'./models/{args.model}_fold_{args.fold + 1}.bin')
    print('model saved.')
