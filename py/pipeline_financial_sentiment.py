# LAB 37 - Natural Language Processing, PDF Sentiment Prediction
# Financial Sentiment Prediction
# Python Scripts for:
#  - loading models and 
#  - performing text sentiment classification/regression pipelines

# Spacy & Text
import spacy
from spacy import displacy
from spacy.lang.en import English
from spacy.lang.en.stop_words import STOP_WORDS
import string

# Data Manipulation
import numpy as np
import pandas as pd

# Scikit Learn
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.pipeline import Pipeline
from sklearn.linear_model import LogisticRegression, LinearRegression

# Save/Load Models
import joblib


# Create our list of punctuation marks
punctuations = string.punctuation

# Create our list of stopwords
stop_words = spacy.lang.en.stop_words.STOP_WORDS

# Load English tokenizer, tagger, parser, NER and word vectors
parser = spacy.load('en_core_web_sm')
#parser = en_core_web_sm.load()

nlp = spacy.load('en_core_web_sm')
#nlp = en_core_web_sm.load()



# Creating our tokenizer function
def spacy_tokenizer(sentence):
    # Creating our token object, which is used to create documents with linguistic annotations.
    mytokens = parser(sentence)
    # Lemmatizing each token and converting each token into lowercase
    mytokens = [ word.lemma_.lower().strip() if word.lemma_ != "-PRON-" else word.lower_ for word in mytokens ]
    # Removing stop words
    mytokens = [ word for word in mytokens if word not in stop_words and word not in punctuations ]
    # return preprocessed list of tokens
    return mytokens

def pipeline_classification(X):
    classification_pipeline = joblib.load("models/pipe_logistic_regression.sav")
    return classification_pipeline.predict(X)

def pipeline_regression(X):
    regression_pipeline = joblib.load("models/pipe_linear_regression.sav")
    return regression_pipeline.predict(X)

def pipeline_entityreco(X):
    doc = nlp(X)
    html_py = displacy.render(doc, style="ent") 
    return html_py

