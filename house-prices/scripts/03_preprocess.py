from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer

# IMPUTATION PIPELINE

# Cols need imputation
none_cols = [
    'PoolQC','MiscFeature','Alley','Fence','FireplaceQu',
    'GarageType','GarageFinish','GarageQual','GarageCond',
    'BsmtFinType2','BsmtExposure','BsmtCond','BsmtFinType1','BsmtQual',
    'MasVnrType'
]
median_cols = ['LotFrontage', 'MasVnrArea']
garage_cols = ['GarageYrBlt']

# Define imputer
none_imputer = SimpleImputer(strategy="constant", fill_value="None")
median_imputer = SimpleImputer(strategy="median")
garage_imputer = SimpleImputer(strategy="constant", fill_value=0)

# Preprocessor
preprocessor = ColumnTransformer(
    transformers=[
        ("none_imputer", none_imputer, none_cols),
        ("median_imputer", median_imputer, median_cols),
        ("garage_imputer", garage_imputer, garage_cols),
    ],
    remainder="passthrough"
)

# FEATURE ENGINEERING

def feature_engineering_pipeline(df):

    df = df.copy()
    
    # Create time based features
    df['HouseAge'] = df['YrSold'] - df['YearBuilt']
    df['YearsSinceRemodel'] = df['YrSold'] - df['YearRemodAdd']
    df['YearsSinceGarage'] = df['YrSold'] - df['GarageYrBlt']
    df['YearsSinceSold'] = df['YrSold'].max() - df['YrSold']
    
    # drop original year columns
    df = df.drop(['YearBuilt', 'YearRemodAdd', 'YrSold', 'GarageYrBlt'], axis=1)
    
    # Create area feature
    df['TotalSF'] = df['GrLivArea'] + df['TotalBsmtSF']
    
    # Create bathroom feature
    df['TotalBath'] = (df['BsmtFullBath'] + 
                       df['FullBath'] + 
                       0.5 * (df['BsmtHalfBath'] + df['HalfBath']))
    
    return df
