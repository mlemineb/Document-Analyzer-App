ui <- dashboardPage(
  
  
  title = 'Financial PDF Analyzer',
  dashboardHeader(title = "Document Analyzer"),
  dashboardSidebar(
    sidebarMenu(id = "sidebarmenu",
                
                
                HTML(paste0(
                    "<br>",
                    "<a <center><img src='logo2.png' style='width: 90%; height: 90%'></center></a>",
                    "<br>"
                )),
                
                menuItem("Home", tabName = "home", icon = icon("home")),
                menuItem("How it works ?", tabName = "how", icon = icon("question-sign",lib = "glyphicon")),
                menuItem("Analyze Paragraph Sentiment", tabName = "sentiment", icon = icon("comment")),
                menuItem(tabName = "topic", "Analyze Paragraph Topic", icon = icon("align-left")),
                menuItem(tabName = "entity", "Entity Recognition", icon = icon("chart-pie")),
                menuItem(tabName = "tabextract", "Extract Table", icon = icon("table")),
                
                
                
                HTML(paste0(
                  "<br><br><br><br><br><br><br><br><br><br><br><br>",
                  "<table style='margin-left:auto; margin-right:auto;'>",
                  "<tr>",
                  "<td style='padding: 5px;'><a href='https://twitter.com/m_lemine_b' target='_blank'><i class='fab fa-twitter fa-lg'style='color:#DDDDDD;'></i></a></td>",
                  "<td style='padding: 5px;'><a href='https://www.linkedin.com/in/mohamed-lemine-beydia/' target='_blank'><i class='fab fa-linkedin fa-lg'style='color:#DDDDDD;'></i></a></td>",
                  "</tr>",
                  "</table>",
                  "<br>"),
                  HTML(paste0(
                    "<script>",
                    "var today = new Date();",
                    "var yyyy = today.getFullYear();",
                    "</script>",
                    "<p style = 'text-align: center;'><small>&copy; - <a href='mailto:m.beydia@gmail.com'style='color:#DDDDDD'; target='_blank'>Mohamed Beydia</a> - <script>document.write(yyyy);</script></small></p>")
                  ))
                
    )
  ),
  dashboardBody(
    ### changing theme
    shinyDashboardThemes(
      theme = "poor_mans_flatly"
    ),
    
    useShinyjs(),
    introjsUI(),
    
    tabItems(
      tabItem(tabName = "home",HTML('<center><img src="home_page.gif" style="width: 90%; height: 90%"></center>')),
      tabItem(tabName = "how",HTML('<center><img src="My_homepage.png" style="width: 80%; height: 80%"></center>'))
      ,
      tabItem(tabName = "sentiment",
              tabPanel(
                title = "Analyze Text Sentiment",
                includeCSS("css/styles.css"),
                sidebarLayout(
                  # * SIDEBAR ----
                  sidebarPanel(
                    width = 3,
                    h3("PDF Text Extraction & NLP"),
                    HTML("<p>This module allows you to import the pdf file that will be used for the next 2 modules and perform a <strong>Sentiment Analysis</strong> for each paragraph. 
                     The extraction of relevant features from the pdf is done with <Code>R</code>,via the packages <Code>Tidyverse, pdftools, magick</code>.
                     The analysis part is done with <Code>Python</code> :  <strong>NLP porcessing</strong> via <Code>Spacy</code> and <strong>sentiment scoring (machine learning)</strong> via <Code>Sklear</code> with an SGD (stockastic gradient descent).
                         
                         <a <center><img src='text_sent.png' style='width: 100%; height: 100%'></center></a>"),
                    hr(),
                    shiny::fileInput(inputId = "pdf_input", label = "Select PDF File", accept = ".pdf"),
                    shiny::actionButton(inputId = "submit", "Run NLP", class = "btn-primary"),
                    hr()
                    
                  ),
                  # * MAIN ----
                  mainPanel(
                    width = 9,
                    div(
                      class = "col-sm-6 panel",
                      div(class= "panel-heading", h5("PDF Viewer")),
                      div(
                        class="panel-body", style="height:700px",  
                        withSpinner(imageOutput("img_pdf", width = "100%", height = "600px"),color='#18BC9C'),
                        uiOutput("page_controls")
                      )
                    ),
                    div(
                      class = "col-sm-6 panel",
                      div(class= "panel-heading", h5("Sentiment Analysis")),
                      div(
                        class="panel-body", style="height:700px",  
                        withSpinner( plotlyOutput("plolty_sentiment", height = "600px"),color='#18BC9C')
                        # verbatimTextOutput(outputId = "print")
                      )
                    )
                  )
                )
              )
      ),
      
      
      tabItem(tabName = "topic",fluidRow(
          tags$style('#page_summariz {   height: 600px;   overflow: auto;}'),
          tags$script(
              '
    Shiny.addCustomMessageHandler("scrollCallback",
    function(msg) {
    console.log("aCMH" + msg)
    var objDiv = document.getElementById("page_summariz");
    objDiv.scrollTop = objDiv.scrollHeight - objDiv.clientHeight;
    console.dir(objDiv)
    console.log("sT:"+objDiv.scrollTop+" = sH:"+objDiv.scrollHeight+" cH:"+objDiv.clientHeight)
    }
    );'
          ),
              tabPanel(
                  title = "Summarize Page Text",
                  includeCSS("css/styles.css"),
                  sidebarLayout(
                      # * SIDEBAR ----
                      sidebarPanel(
                          width = 3,
                          h3("PDF Text Extraction & NLP"),
                          HTML("This module allows you to make a <strong>Text Summarization</strong> for each page of the previously downloaded pdf.
                               Text Summarization is done with <code>R</code> via <code>LexRank</code> which is a <strong>graph-based stochastic</strong> 
                               method to find the important sentences in the text to create meaningful summaries.
                               
                               <a <center><img src='text_summarize.png' style='width: 100%; height: 100%'></center></a>"),
                          hr(),

                      ),
                      # * MAIN ----
                      mainPanel(
                          width = 9,
                          div(
                              class = "col-sm-6 panel",
                              div(class= "panel-heading", h5("PDF Viewer")),
                              div(
                                  class="panel-body", style="height:700px",  
                                  withSpinner( imageOutput("img_pdf2", width = "100%", height = "600px"), color='#18BC9C'),
                                  uiOutput("page_summariz_contr")
                              )
                          ),
                          div(
                              class = "col-sm-6 panel",
                              div(class= "panel-heading", h5("Page Summary")),
                              div(
                                  class="panel-body", style="height:700px",  
                                  withSpinner( uiOutput("page_summariz"),color='#18BC9C')
                                  # verbatimTextOutput(outputId = "print")
                              )
                          ),
                          
                          h3("WordCloud"),
 
                          withSpinner( wordcloud2Output("word_cloud"),color='#18BC9C')
                              
                          
                      )
                  )
              ))),
      
      tabItem(tabName = "entity", fluidRow(
          
          tags$style('#ent_recognition {   height: 600px;   overflow: auto;}'),
          tags$script(
              '
    Shiny.addCustomMessageHandler("scrollCallback",
    function(msg) {
    console.log("aCMH" + msg)
    var objDiv = document.getElementById("ent_recognition");
    objDiv.scrollTop = objDiv.scrollHeight - objDiv.clientHeight;
    console.dir(objDiv)
    console.log("sT:"+objDiv.scrollTop+" = sH:"+objDiv.scrollHeight+" cH:"+objDiv.clientHeight)
    }
    );'
          ),
              tabPanel(
                  title = "Entity Recognition",
                  includeCSS("css/styles.css"),
                  sidebarLayout(
                      # * SIDEBAR ----
                      sidebarPanel(
                          width = 3,
                          h3("PDF Text Extraction & NLP"),
                          HTML("<p>This module allows you to import the pdf file that will be used for the next 2 modules and perform a <strong>Sentiment Analysis</strong> for each paragraph. 
                     The extraction of relevant features from the pdf is done with <Code>R</code>,via the packages <Code>Tidyverse, pdftools, magick</code>.
                     The analysis part is done with <Code>Python</code> :  <strong>NLP porcessing</strong> via <Code>Spacy</code> and <strong>sentiment scoring (machine learning)</strong> via <Code>Sklear</code> with an SGD (stockastic gradient descent).
                         
                         <a <center><img src='text_entity.png' style='width: 100%; height: 100%'></center></a>"),
                          hr()
                          
                      ),
                      # * MAIN ----
                      mainPanel(
                          width = 9,
                          div(
                              class = "col-sm-6 panel",
                              div(class= "panel-heading", h5("PDF Viewer")),
                              div(
                                  class="panel-body", style="height:700px",  
                                  withSpinner( imageOutput("img_pdf3", width = "100%", height = "600px"),color='#18BC9C'),
                                  uiOutput("page_controls3")
                              )
                          ),
                          div(
                              class = "col-sm-6 panel",
                              div(class= "panel-heading", h5("Entity Recognition")),
                              div(
                                  class="panel-body", style="height:700px",  
                                  withSpinner(  uiOutput("ent_recognition"),color='#18BC9C')
                                  # verbatimTextOutput(outputId = "print")
                              )
                          )
                      )
                  )
              ))),
    
      tabItem(tabName = "tabextract",
              fluidPage(
                  useShinyjs(),
                  includeCSS("css/styles.css"),
                  
                  
                  tags$head(tags$script('
                        var dimension = [0, 0];
                        $(document).on("shiny:connected", function(e) {
                        dimension[0] = window.innerWidth;
                        dimension[1] = window.innerHeight;
                        $("#uploadButton_progress").remove();
                        
                        Shiny.onInputChange("dimension", dimension);
                        });
                        
                        $(window).resize(function(e) {
                        dimension[0] = window.innerWidth;
                        dimension[1] = window.innerHeight;
                        Shiny.onInputChange("dimension", dimension);
                        });
                        ')),
                  tags$head(tags$title("PDF Table Extractor")),
                  
                  
                  column(width=6,
                         # fluidRow(column(width=3, a(img(src="nrgi_logo.png", id='logo'),target="_blank", href="https://resourcegovernance.org/"), style="padding-top:20px"),
                         #          column(width=9, h3("PDF Table Extractor"), style="padding-top:20px")),
                         fluidRow(column(width=1),
                                  column(width=1),
                                  column(width=9, h3("PDF Table Extractor"), style="padding-top:20px")),
                         column(width=12,
                                
                                id="text-row",
                                p("This module allows you to extract structured, machine-readable tables from PDF reports in a few clicks. Load a PDF into the application and extract tables directly into the browser, ready to be exported to CSV format."
                                ),
                                
                                div(class="col-md-4 no-padding url-input",#style="display:inline-block",
                                    textInput("downloadURL", label="", placeholder = "Insert URL for online PDF")),#, width="110px", style=""),
                                div(class="col-md-2",#style="display:inline-block",
                                    actionButton("downloadButton", label="Load URL")),
                                div(class="col-md-2", id="uploadButton-div",style="display:inline-block",
                                    shiny::fileInput("uploadButton", label="Local source", accept=".pdf")),
                                div(class="col-md-2",
                                    downloadButton("fileDownload", "Download")),
                                bsTooltip("downloadButton", placement = "top", trigger="hover", title="Download a PDF from the web for scraping. URL must point directly to the PDF."),
                                bsTooltip("uploadButton-div", placement = "top", trigger="hover", title="Upload a PDF from your computer for scraping. Size limit: 8mb")
                         ),
                         column(width=12,
                                id="scrapeRow",
                                div(class="col-md-6 no-padding url-input",
                                    textInput("pageNumber", label="", placeholder = 'Page(s). For multiple: "1,2,7" or "5:10"')),
                                div(class="col-md-2",#style="display:inline-block",
                                    actionButton("scrapeButton", label="Scrape")),
                                div(class="col-md-2",#style="display:inline-block",
                                    actionButton("drawButton", label="Custom scrape")),
                                bsTooltip("scrapeButton", placement = "top", trigger="hover", title="Click here to auto detect the table on the page(s)."),
                                bsTooltip("drawButton", placement = "top", trigger="hover", title="Click here to drag a rectangle around the table in your PDF. Works one page at a time.")
                         ),
                         
                         div(class="col-md-12", rHandsontableOutput("hot"))#,
                         # img(src="nrgi_logo.jpg", id="logo")#, bottom="0", left="0", height="100px", position="fixed")
                  ),
                  
                  column(width=6,
                         style="height:100%",
                         actionButton("done", label="Done"),
                         actionButton("cancel", label="Cancel"),
                         plotOutput("plot", height = "800px", brush = shiny::brushOpts(id = "plot_brush")),
                         htmlOutput("pdfOut", class="pdf")
                  )
              )
              )
      
      
    )
    
    
    
  )
)





