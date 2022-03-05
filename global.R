library(magick)

# Plotting
library(plotly)

# Core
library(tidyverse)
library(tidyquant)

# Python
library(reticulate)

library(shiny)
library(shinydashboard)
library(shinycssloaders)
library(DT)
library(data.table)
library(dplyr)
library(plotly)
library(rintrojs)
library(shinyjs)
library(dashboardthemes)
library(echarts4r)
library(pdftools)
library(lexRankr)
library(furrr)
library(tidytext)
library(rhandsontable)
library(shinyBS)
library(png)
library(httr)
library(shinythemes)
library(wordcloud2)
library(tidytext)


# PYTHON SETUP ----

# Replace this with your conda environment containing sklearn, pandas, numpy, spacy
#use_virtualenv("py3.6", required = TRUE)


# Define any Python packages needed for the app here:
PYTHON_DEPENDENCIES = c('pip', 'numpy','pandas','spacy','sklearn')

# Begin app server

  # ------------------ App virtualenv setup (Do not edit) ------------------- #
  
  virtualenv_dir = 'py_doc_analyzer'

  # Create virtual env and install dependencies
  #reticulate::virtualenv_create(envname = 'py_doc_analyzer')
  #reticulate::virtualenv_install(virtualenv_dir, packages = PYTHON_DEPENDENCIES, ignore_installed=TRUE)
  reticulate::use_virtualenv(virtualenv_dir, required = T)
  #reticulate::repl_python(input = '!python -m spacy download en_core_web_sm')
  source_python("py/pipeline_financial_sentiment.py")

# DATA SETUP ----
