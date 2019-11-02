import pandas as pd
import numpy as np


class tbl:
    def __init__(self,name="mtcars"):
        self.name = name
        self.df = pd.read_csv(f'..\\data\\{name}.csv')
    def summary(self):
        df = self.df
        numeric_df = df.select_dtypes(include=['int64','float64'])
        return pd.DataFrame ({"Minimum":numeric_df.min(),
                         "Mean":numeric_df.mean(),
                         "Median":numeric_df.median(),
                         "Maximum":numeric_df.max(),})
    def __str__(self):
        return self.name + '.csv'
        