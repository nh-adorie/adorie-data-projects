from sklearn.pipeline import Pipeline
from sklearn.base import BaseEstimator, TransformerMixin
from sklearn.preprocessing import OneHotEncoder, OrdinalEncoder, StandardScaler
import pandas as pd
import numpy as np
from features_group import numeric, categorical_nominal, categorical_ordinal, boolean

# 1. IMPUTATION TRANSFORMER
class CustomImputer(BaseEstimator, TransformerMixin):
    def __init__(self):
        self.none_cols = [
            'PoolQC', 'MiscFeature', 'Alley', 'Fence', 'FireplaceQu',
            'GarageType', 'GarageFinish', 'GarageQual', 'GarageCond',
            'BsmtFinType2', 'BsmtExposure', 'BsmtCond', 'BsmtFinType1', 
            'BsmtQual', 'MasVnrType'
        ]
        self.median_cols = ['LotFrontage', 'MasVnrArea']
        self.garage_col = 'GarageYrBlt'
        self.medians_ = {}
        self.zero_cols = [
        'BsmtFinSF1', 'BsmtFinSF2', 'BsmtUnfSF', 'TotalBsmtSF',
        'BsmtFullBath', 'BsmtHalfBath', 'GarageCars', 'GarageArea'
        ] # Thêm phần này vào vì khi process test data với cùng pipeline cũ thì chỗ này bị NA
        
    
    def fit(self, X, y=None):
        for col in self.median_cols:
            if col in X.columns:
                self.medians_[col] = X[col].median()
        return self
    
    def transform(self, X):
        X = X.copy()
        
        for col in self.zero_cols:
            if col in X.columns:
                X[col] = X[col].fillna(0)

        for col in self.none_cols:
            if col in X.columns:
                X[col] = X[col].fillna('None')
        
        for col in self.median_cols:
            if col in X.columns:
                X[col] = X[col].fillna(self.medians_.get(col, 0))
        
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
        
        X['YearsSinceGarage'] = np.where(
            X['GarageYrBlt'] == 0,
            0,
            X['YrSold'] - X['GarageYrBlt']
        )
        
        X['YearsSinceSold'] = X['YrSold'].max() - X['YrSold']
        
        X = X.drop(['YearBuilt', 'YearRemodAdd', 'YrSold', 'GarageYrBlt'], axis=1)
        
        # Area features
        X['TotalSF'] = X['GrLivArea'] + X['TotalBsmtSF']
        
        # Bathroom features
        X['TotalBath'] = (X['BsmtFullBath'] + X['FullBath'] + 
                         0.5 * (X['BsmtHalfBath'] + X['HalfBath']))
        
        return X

# 3. ENCODING TRANSFORMER (FIXED)
class FeatureEncoder(BaseEstimator, TransformerMixin):
    
    def __init__(self):
        self.ordinal_mapping = {
            'ExterQual': ['Po', 'Fa', 'TA', 'Gd', 'Ex'],
            'ExterCond': ['Po', 'Fa', 'TA', 'Gd', 'Ex'],
            'BsmtQual': ['None', 'Po', 'Fa', 'TA', 'Gd', 'Ex'],
            'BsmtCond': ['None', 'Po', 'Fa', 'TA', 'Gd', 'Ex'],
            'BsmtExposure': ['None', 'No', 'Mn', 'Av', 'Gd'],
            'BsmtFinType1': ['None', 'Unf', 'LwQ', 'Rec', 'BLQ', 'ALQ', 'GLQ'],
            'BsmtFinType2': ['None', 'Unf', 'LwQ', 'Rec', 'BLQ', 'ALQ', 'GLQ'],
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
        
        self.ohe = OneHotEncoder(sparse_output=False, handle_unknown="ignore", drop=None)
        # handle_unknow = ignore giúp bỏ qua các giá trị mới trong test data

        self.oe = OrdinalEncoder(
            categories=list(self.ordinal_mapping.values()),
            handle_unknown='use_encoded_value',
            unknown_value=-1
        )
    
    def fit(self, X, y=None):
        X = X.copy()
        
        # Identify columns present in data
        self.nom_cols_present = [c for c in self.categorical_nominal if c in X.columns]
        self.ord_cols_present = [c for c in self.ordinal_cols if c in X.columns]
        self.bool_cols_present = [c for c in self.boolean_cols if c in X.columns]
        
        # Fit encoders
        if self.nom_cols_present:
            self.ohe.fit(X[self.nom_cols_present])
        
        if self.ord_cols_present:
            self.oe.fit(X[self.ord_cols_present])
        
        # Get remaining numeric columns (after dropping categorical and boolean)
        cols_to_drop = self.nom_cols_present + self.ord_cols_present + self.bool_cols_present
        self.numeric_cols = [c for c in X.columns if c not in cols_to_drop]
        
        # Build feature names in fixed order
        self.feature_names_ = []
        
        # 1. Numeric columns
        self.feature_names_.extend(self.numeric_cols)
        
        # 2. OneHot encoded columns
        if self.nom_cols_present:
            self.feature_names_.extend(self.ohe.get_feature_names_out(self.nom_cols_present).tolist())
        
        # 3. Ordinal encoded columns
        self.feature_names_.extend(self.ord_cols_present)
        
        # 4. Boolean columns
        self.feature_names_.extend(self.bool_cols_present)
           
        return self
    
    def transform(self, X):
        X = X.copy()
        
        # 1. Get numeric columns
        numeric_df = X[self.numeric_cols].copy()
        
        # 2. OneHot encoding
        if self.nom_cols_present:
            ohe_array = self.ohe.transform(X[self.nom_cols_present])
            ohe_df = pd.DataFrame(
                ohe_array,
                columns=self.ohe.get_feature_names_out(self.nom_cols_present),
                index=X.index
            )
        else:
            ohe_df = pd.DataFrame(index=X.index)
        
        # 3. Ordinal encoding
        if self.ord_cols_present:
            ord_array = self.oe.transform(X[self.ord_cols_present])
            ordinal_df = pd.DataFrame(
                ord_array,
                columns=self.ord_cols_present,
                index=X.index
            )
        else:
            ordinal_df = pd.DataFrame(index=X.index)
        
        # 4. Boolean encoding
        if self.bool_cols_present:
            boolean_df = X[self.bool_cols_present].apply(
                lambda s: s.map({"Y": 1, "N": 0}).fillna(0)
            )
        else:
            boolean_df = pd.DataFrame(index=X.index)
        
        # Concatenate all parts
        X_encoded = pd.concat([numeric_df, ohe_df, ordinal_df, boolean_df], axis=1)
        
        # Ensure all expected features exist (fill missing with 0)
        for col in self.feature_names_:
            if col not in X_encoded.columns:
                X_encoded[col] = 0
        
        # Return in the exact order from training
        X_encoded = X_encoded[self.feature_names_]
        # sắp xếp theo đúng thứ tự trong train data

        return X_encoded

# 4. FULL PREPROCESSING PIPELINE
def create_preprocessing_pipeline():
    pipeline = Pipeline([
        ('imputer', CustomImputer()),
        ('feature_engineer', FeatureEngineer()),
        ('encoder', FeatureEncoder())
    ])
    
    return pipeline

def preprocess_data(X_train, X_test=None):
    pipeline = create_preprocessing_pipeline()
    
    X_train_processed = pipeline.fit_transform(X_train)
    
    if X_test is not None:
        X_test_processed = pipeline.transform(X_test)
        return X_train_processed, X_test_processed, pipeline
    
    return X_train_processed, pipeline