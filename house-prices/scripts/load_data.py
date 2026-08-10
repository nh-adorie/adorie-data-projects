import pandas as pd

def load_data(path):
    return pd.read_csv(path)

def split_xy(df):
    y = df["SalePrice"]
    X = df.drop(columns=["SalePrice"])
    return X, y