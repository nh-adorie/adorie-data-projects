numeric = [
    'LotFrontage','LotArea','MasVnrArea','TotalBsmtSF','GrLivArea',
    '1stFlrSF','2ndFlrSF','LowQualFinSF','BsmtFinSF1','BsmtFinSF2',
    'BsmtUnfSF','BsmtFullBath','BsmtHalfBath','FullBath','HalfBath',
    'BedroomAbvGr','KitchenAbvGr','TotRmsAbvGrd','Fireplaces',
    'GarageCars','GarageArea','WoodDeckSF','OpenPorchSF',
    'EnclosedPorch','ScreenPorch','3SsnPorch','PoolArea','MiscVal'
]

categorical_nominal = [
    'MSSubClass','MSZoning','Street','Alley','Utilities','LotConfig',
    'Neighborhood','Condition1','Condition2','BldgType','HouseStyle',
    'RoofStyle','RoofMatl','Exterior1st','Exterior2nd','MasVnrType',
    'Foundation','Heating','Electrical','Functional','GarageType',
    'PavedDrive','MiscFeature','SaleType','SaleCondition'
]

categorical_ordinal = [
    'LotShape','LandContour','LandSlope','ExterQual','ExterCond',
    'BsmtQual','BsmtCond','BsmtExposure','BsmtFinType1','HeatingQC',
    'KitchenQual','FireplaceQu','GarageFinish','GarageQual',
    'GarageCond','PoolQC','Fence'
]

boolean = ['CentralAir']

year = ['YearBuilt', 'YearRemodAdd', 'YrSold', 'GarageYrBlt']

