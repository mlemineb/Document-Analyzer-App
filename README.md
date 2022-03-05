# Financial Document Analyzer
A Shiny application that analyzes financial documents (pdf format) using NLP and machine learning.

Basically the app takes as input a pdf file, applies data cleaning and NLP processing and give back :
- a sentiment score for each paragraph ( done with Python via Spacy and Sckit-learn)
- text summarization for each page ( done with R via LexRank algorithm)
- entity recognition for each page ( done with Python via Spacy)
- tool for extracting tables from document and download as csv file
## How it works
![Alt text](www/My_homepage.png?raw=true "How it Works")
