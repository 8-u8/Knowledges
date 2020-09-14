# encoding:utf-8
'''
todo 

1. find MNIST data csv
    - how to convert images to csv? -> done(from kaggle)
2. folds
    - data['fold'] = fold number.
3. save.

'''

import pandas as pd
from sklearn import model_selection

def create_df_with_folds(df, randomize=False):
    # we create a new column called "kfold" and fill it with -1.
    df['kfold'] = -1

    # the next step is to randomize the rows of the data(maybe base data is different.)
    if randomize:
        df = df.sample(frac=1).reset_index(drop=True)
    
    kf = model_selection.KFold(n_splits=5)

    # fill the new kfold column
    for fold, (trn_, val_) in enumerate(kf.split(X=df)):
        df.loc[val_, 'kfold'] = fold

    # return df with new kfold column
    return df

