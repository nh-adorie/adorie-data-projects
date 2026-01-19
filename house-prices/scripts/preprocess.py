from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.impute import SimpleImputer
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.preprocessing import OneHotEncoder, OrdinalEncoder, StandardScaler
import pandas as pd
import numpy as np
from features_group import numeric, categorical_nominal, categorical_ordinal, boolean


# 1. IMPUTATION TRANSFORMER

class CustomImputer(BaseEstimator, TransformerMixin):
    
    def __init__(self):
        # Columns need 'None' imputation
        self.none_cols = [
            'PoolQC', 'MiscFeature', 'Alley', 'Fence', 'FireplaceQu',
            'GarageType', 'GarageFinish', 'GarageQual', 'GarageCond',
            'BsmtFinType2', 'BsmtExposure', 'BsmtCond', 'BsmtFinType1', 
            'BsmtQual', 'MasVnrType'
        ]
        
        # Columns need median imputation
        self.median_cols = ['LotFrontage', 'MasVnrArea']
        
        # GarageYrBlt needs 0 (will be handled in feature engineering)
        self.garage_col = 'GarageYrBlt'
        
        self.medians_ = {}
    
    def fit(self, X, y=None):
        # Calculate medians for numeric columns
        for col in self.median_cols:
            if col in X.columns:
                self.medians_[col] = X[col].median()
        return self
    
    def transform(self, X):
        X = X.copy()
        
        # Fill 'None' for categorical
        for col in self.none_cols:
            if col in X.columns:
                X[col] = X[col].fillna('None')
        
        # Fill median for numeric
        for col in self.median_cols:
            if col in X.columns:
                X[col] = X[col].fillna(self.medians_.get(col, 0))
        
        # Fill 0 for GarageYrBlt
        if self.garage_col in X.columns:
            X[self.garage_col] = X[self.garage_col].fillna(0)
        
        return X


# 2. FEATURE ENGINEERING TRANSFORMER

class FeatureEngineer(BaseEstimator, TransformerMixin):
    
    def fit(self, X, y=None):
        return self
    
    def transform(self, X):
        X = X.copy()
        
        # Time-based features
        X['HouseAge'] = X['YrSold'] - X['YearBuilt']
        X['YearsSinceRemodel'] = X['YrSold'] - X['YearRemodAdd']
        
        # Handle GarageYrBlt = 0 (no garage)
        X['YearsSinceGarage'] = np.where(
            X['GarageYrBlt'] == 0,
            0,  # No garage
            X['YrSold'] - X['GarageYrBlt']
        )
        
        X['YearsSinceSold'] = X['YrSold'].max() - X['YrSold']
        
        # Drop original year columns
        X = X.drop(['YearBuilt', 'YearRemodAdd', 'YrSold', 'GarageYrBlt'], axis=1)
        
        # Area features
        X['TotalSF'] = X['GrLivArea'] + X['TotalBsmtSF']
        
        # Bathroom features
        X['TotalBath'] = (X['BsmtFullBath'] + X['FullBath'] + 
                         0.5 * (X['BsmtHalfBath'] + X['HalfBath']))
        
        return X


# 3. ENCODING TRANSFORMER

class FeatureEncoder(BaseEstimator, TransformerMixin):
    
    def __init__(self):
        # Ordinal mapping
        self.ordinal_mapping = {
            'ExterQual': ['Po', 'Fa', 'TA', 'Gd', 'Ex'],
            'ExterCond': ['Po', 'Fa', 'TA', 'Gd', 'Ex'],
            'BsmtQual': ['None', 'Po', 'Fa', 'TA', 'Gd', 'Ex'],
            'BsmtCond': ['None', 'Po', 'Fa', 'TA', 'Gd', 'Ex'],
            'BsmtExposure': ['None', 'No', 'Mn', 'Av', 'Gd'],
            'BsmtFinType1': ['None', 'Unf', 'LwQ', 'Rec', 'BLQ', 'ALQ', 'GLQ'],
            'HeatingQC': ['Po', 'Fa', 'TA', 'Gd', 'Ex'],
            'KitchenQual': ['Po', 'Fa', 'TA', 'Gd', 'Ex'],
            'FireplaceQu': ['None', 'Po', 'Fa', 'TA', 'Gd', 'Ex'],
            'GarageFinish': ['None', 'Unf', 'RFn', 'Fin'],
            'GarageQual': ['None', 'Po', 'Fa', 'TA', 'Gd', 'Ex'],
            'GarageCond': ['None', 'Po', 'Fa', 'TA', 'Gd', 'Ex'],
            'PoolQC': ['None', 'Fa', 'TA', 'Gd', 'Ex'],
            'Fence': ['None', 'MnWw', 'GdWo', 'MnPrv', 'GdPrv'],
            'LotShape': ['IR3', 'IR2', 'IR1', 'Reg'],
            'LandContour': ['Low', 'HLS', 'Bnk', 'Lvl'],
            'LandSlope': ['Sev', 'Mod', 'Gtl']
        }
        
        self.categorical_nominal = categorical_nominal
        self.ordinal_cols = list(self.ordinal_mapping.keys())
        self.boolean_cols = boolean
        
        self.ohe = OneHotEncoder(sparse_output=False, handle_unknown="ignore")
        self.oe = OrdinalEncoder(
            categories=list(self.ordinal_mapping.values()),
            handle_unknown='use_encoded_value',
            unknown_value=-1
        )
    
    def fit(self, X, y=None):
        X = X.copy()
        
        # Fit OneHotEncoder
        if len(self.categorical_nominal) > 0:
            nom_cols_present = [c for c in self.categorical_nominal if c in X.columns]
            if nom_cols_present:
                self.ohe.fit(X[nom_cols_present])
                self.nom_cols_present = nom_cols_present
            else:
                self.nom_cols_present = []
        
        # Fit OrdinalEncoder
        ord_cols_present = [c for c in self.ordinal_cols if c in X.columns]
        if ord_cols_present:
            self.oe.fit(X[ord_cols_present])
            self.ord_cols_present = ord_cols_present
        else:
            self.ord_cols_present = []
        
        return self
    
    def transform(self, X):
        X = X.copy()
        
        # OneHotEncoder
        if self.nom_cols_present:
            ohe_arr = self.ohe.transform(X[self.nom_cols_present])
            ohe_df = pd.DataFrame(
                ohe_arr,
                columns=self.ohe.get_feature_names_out(self.nom_cols_present),
                index=X.index
            )
        else:
            ohe_df = pd.DataFrame(index=X.index)
        
        # OrdinalEncoder
        if self.ord_cols_present:
            ordinal_arr = self.oe.transform(X[self.ord_cols_present])
            ordinal_df = pd.DataFrame(
                ordinal_arr,
                columns=self.ord_cols_present,
                index=X.index
            )
        else:
            ordinal_df = pd.DataFrame(index=X.index)
        
        # Boolean
        for col in self.boolean_cols:
            if col in X.columns:
                X[col] = X[col].map({"Y": 1, "N": 0}).fillna(0)
        
        # Drop original categorical columns
        cols_to_drop = (self.nom_cols_present + self.ord_cols_present)
        X = X.drop(columns=cols_to_drop, errors='ignore')
        
        # Concatenate
        X = pd.concat([X, ohe_df, ordinal_df], axis=1)
        
        return X

# 4. FULL PREPROCESSING PIPELINE

def create_preprocessing_pipeline():

    pipeline = Pipeline([
        ('imputer', CustomImputer()),
        ('feature_engineer', FeatureEngineer()),
        ('encoder', FeatureEncoder())
    ])
    
    return pipeline


def preprocess_data(X_train, X_test=None):

    # Create pipeline
    pipeline = create_preprocessing_pipeline()
    
    # Fit and transform train
    X_train_processed = pipeline.fit_transform(X_train)
    
    if X_test is not None:
        # Transform test
        X_test_processed = pipeline.transform(X_test)
        return X_train_processed, X_test_processed, pipeline
    
    return X_train_processed, pipeline