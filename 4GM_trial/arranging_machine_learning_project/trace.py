# encoding: utf-8
import pandas as pd
from sklearn import model_selection
from src.create_folds import create_df_with_folds

if __name__ == "__main__":
    df = pd.read_csv('./input/mnist_train.csv')

    df = create_df_with_folds(df, randomize=False)

    df.to_csv('./input/mnist_train_folds.csv', index=False)
