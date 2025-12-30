def import_packages():
    # Import packages

    # For file handling
    import os

    # For data manipulation 
    import numpy as np
    import pandas as pd

    # For data visualization
    import matplotlib.pyplot as plt
    import seaborn as sns
    from matplotlib.ticker import PercentFormatter

    # For displaying all of the columns in dataframes
    pd.set_option('display.max_columns', None)

    # For data modeling
    from xgboost import XGBClassifier
    from xgboost import XGBRegressor
    from xgboost import plot_importance

    from sklearn.linear_model import LogisticRegression
    from sklearn.tree import DecisionTreeClassifier
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.preprocessing import StandardScaler
    from sklearn.preprocessing import LabelEncoder

    # For metrics and helpful functions
    from sklearn.model_selection import GridSearchCV, train_test_split
    from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix, ConfusionMatrixDisplay, classification_report
    from sklearn.metrics import roc_auc_score, roc_curve
    from sklearn.tree import plot_tree

    # For saving models
    import pickle