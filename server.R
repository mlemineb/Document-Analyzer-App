server <- function(session, input, output) {
    
    #------------------------------------------  PAGE 1 ----------------------------------------#
    
    # Limit PDF Files to 10MB
    options(shiny.maxRequestSize = 10*1024^2)
    
    rv <- reactiveValues()
    
    observeEvent(input$submit, {
        
        # Handle Inputs
        req(input$pdf_input)
        
        rv$pdf <- input$pdf_input
        
        
        # Read Text from PDF
        rv$text_data <- pdf_text(rv$pdf$datapath)
        
        rv$paragraph_text_tbl <- tibble(
            # Page Text
            page_text = rv$text_data
        ) %>%
            rowid_to_column(var = "page_num") %>%
            
            # Paragraph Text
            mutate(paragraph_text = str_split(page_text, pattern = "\\.\n")) %>%
            select(-page_text) %>%
            unnest(paragraph_text) %>%
            rowid_to_column(var = "paragraph_num") %>%
            select(page_num, paragraph_num, paragraph_text)
        
        # Modeling
        rv$sentiment_classification <- rv$paragraph_text_tbl %>% 
            pull(paragraph_text) %>%
            pipeline_classification()
        
        rv$sentiment_regression <- rv$paragraph_text_tbl %>% 
            pull(paragraph_text) %>%
            pipeline_regression()
        
        # Data Prep
        rv$data_prepared_tbl <- rv$paragraph_text_tbl %>%
            mutate(
                sentiment_classification = rv$sentiment_classification,
                sentiment_regression     = rv$sentiment_regression
            ) %>%
            mutate(label = str_glue("Page: {page_num}
                            Paragraph: {paragraph_num}
                            Sentiment: {round(sentiment_regression)}
                            ---
                            {str_wrap(paragraph_text, width = 80)}"))
        
        
        rv$data_prepared_tbl_page <- rv$paragraph_text_tbl %>% 
            group_by(page_num) %>% 
            mutate(page_text = paste0(paragraph_text, collapse = "")) 
        
        rv$data_prepared_tbl_page <-rv$data_prepared_tbl_page  %>% select(page_num,page_text) %>% dplyr::distinct()
        
        
        page_data<-rv$paragraph_text_tbl
        
        
        myfunc<-function(i) {
            
            
            page_text<-page_data
            page_text$docID<-paste(page_text$page_num,page_text$paragraph_num,sep = '_')
            
            
            page_text = page_text %>% filter (page_num==i)
            
            top_n = tryCatch(lexRankr::lexRank(page_text$paragraph_text,
                                              docId = page_text$docID,
                                              n = 3,
                                              continuous = TRUE),error=function(e) NULL)
            
            return(tryCatch(top_n, error=function(e) e))
            
            
        }
        
        rv$df=furrr::future_map_dfr(1:pdf_length(rv$pdf$datapath),myfunc)
        
        
        rv$doc_summariz<-rv$df %>%
          mutate(
            page_id = gsub("\\_.*","",rv$df$docId)
          ) %>% 
          group_by(page_id) %>% 
          mutate(page_summary = paste0(sentence, collapse = "")) 
        
        rv$doc_summariz_f<-rv$doc_summariz %>% select(page_id,page_summary) %>% dplyr::distinct()
        
        
        n_max <- pdf_length(rv$pdf$datapath)
        
        summariz_func<-function(i) {
          if (i %in% unique(rv$doc_summariz_f$page_id) ) 
          {str2<-paste(dplyr::filter(rv$doc_summariz_f,page_id==i)$page_summary)
          }else {
            str2<-('Insufficient number of words detected to obtain a summary ')
          } 
          
          df=data.frame(str2=str2)
          
        }
        
        
        rv$doc_summariz_f2=furrr::future_map_dfr(1:n_max,summariz_func)
        
        
      
        # Text Processing
        job_tbl <- tibble(
            job_id = 1,
            text      = rv$text_data
        )
        
        ngrams_job_tbl <- job_tbl %>%
            unnest_tokens(
                output   = word,
                input    = text,
                to_lower = TRUE,
                token    = "ngrams",
                n        = 3,
                n_min    = 1,
                # Passed to tokenizers::tokenize_ngrams()
                stopwords = tidytext::stop_words %>%
                    filter(!word == "r") %>%
                    pull(word)
            )
        
        # TF-IDF
        rv$ngrams_job_tf_tbl <- ngrams_job_tbl %>%
            group_by(job_id) %>%
            count(word, sort = TRUE) %>%
            ungroup() %>%
            filter(!str_detect(word, pattern = "[0-9]")) 
        
        rv$ngrams_job_tfidf_tbl <- rv$ngrams_job_tf_tbl %>%
            bind_tf_idf(
                term     = word, 
                document = job_id, 
                n        = n
            )
        
        
    })
    
    
    
    
    # Debugging ----
    output$print <- renderPrint({
        list(
            pdf = rv$pdf,
            text_data = rv$text_data,
            paragraph_text_tbl = rv$paragraph_text_tbl,
            data_prepared_tbl_page = rv$data_prepared_tbl_page,
            sentiment_classification = rv$sentiment_classification,
            df=rv$df
        )
    })
    
    # Render PDF Images ----
    output$img_pdf <- renderImage({
        
        req(rv$pdf)
        
        # Get page num
        page_num <- input$page_num
        
        # Read PDF Images
        rv$img_data <- image_read_pdf(rv$pdf$datapath, pages = page_num)
        
        tmpfile <- rv$img_data %>% 
            image_scale("600") %>%
            image_write(tempfile(fileext='jpg'), format = 'jpg')
        
        # Return a list
        list(src = tmpfile, contentType = "image/jpeg")
    },deleteFile=F)
    
    # Render PDF Viewer Controls -----
    output$page_controls <- renderUI({
        
        req(rv$pdf)
        
        n_max <- pdf_length(rv$pdf$datapath)
        
        div(
            class = "row",
            shiny::sliderInput(
                "page_num", 
                label = NULL, 
                value = 1, min = 1, max = n_max, step = 1, 
                width = "100%")
        )
        
    })
    
    # Render Plotly Sentiment ----
    output$plolty_sentiment <- renderPlotly({
        
        req(rv$data_prepared_tbl)
        
        g <- rv$data_prepared_tbl %>%
            mutate(page_factor = page_num %>% as_factor() %>% fct_reorder(sentiment_regression)) %>%
            ggplot(aes(page_factor, sentiment_regression, color = sentiment_regression)) +
            geom_point(aes(text = label, 
                           size = abs(sentiment_regression))) +
            scale_color_viridis_c() +
            theme_tq() +
            coord_flip() +
            labs(x = "Page Number", y = "Sentiment Score") +
            ggplot2::theme(legend.position = "none")
        
        ggplotly(g, tooltip = "text") 
    })
    
    
    
    ##------------------------------------------------------------- PAGE 2 --------------------------------------------##
    
    # Render PDF Images ----
    output$img_pdf2 <- renderImage({
        
        req(rv$pdf)
        
        
        # Get page num
        page_num2 <- input$page_num2
        
        # Read PDF Images
        rv$img_data <- image_read_pdf(rv$pdf$datapath, pages = page_num2)
        
        tmpfile <- rv$img_data %>% 
            image_scale("600") %>%
            image_write(tempfile(fileext='jpg'), format = 'jpg')
        
        # Return a list
        list(src = tmpfile, contentType = "image/jpeg")
    },deleteFile=F)
    

    
    
    # Render PDF page summary -----
    output$page_summariz_contr <- renderUI({
        
        req(rv$pdf)
        
        n_max <- pdf_length(rv$pdf$datapath)
        
        
        div(
            class = "row",
            shiny::sliderInput(
                "page_num2", 
                label = NULL, 
                value = 1, min = 1, max = n_max, step = 1, 
                width = "100%")
        )
        
    })
    
    
    
    
    # Render PDF page summary -----
    output$page_summariz <- renderUI({
        
        req(rv$doc_summariz_f2)

        
        str0 <- paste('<p style="color:red;font-size:18px;">Summary of Page ', input$page_num2,'</p>')
        
        str1<- paste(rv$doc_summariz_f2$str2[input$page_num2])
        
        HTML(paste(str0, str1, sep = '<br/>'))
        
        
       
        
    })
    
    
  
    output$word_cloud <- renderWordcloud2({
        
        req(rv$ngrams_job_tfidf_tbl)
        
        rv$ngrams_job_tfidf_tbl %>% filter(n>=5) %>%
            select(word, n) %>%
            rename(freq = n) %>%
            wordcloud2(
                size = 1.5,
                color = palette_light() %>% unname() %>% rep(4)
            )
        
    })
   

    
    
    ##------------------------------------------------------------- PAGE 3 --------------------------------------------##
    
    # Render PDF Images ----
    output$img_pdf3 <- renderImage({
        
      
        req(rv$pdf)
        

        # Get page num
        page_num3 <- input$page_num3
        
        # Read PDF Images
        rv$img_data <- image_read_pdf(rv$pdf$datapath, pages = page_num3)
        
        tmpfile <- rv$img_data %>% 
            image_scale("600") %>%
            image_write(tempfile(fileext='jpg'), format = 'jpg')
        
       
        
        # Return a list
        list(src = tmpfile, contentType = "image/jpeg")
    },deleteFile=F)
    
    # Render PDF Viewer Controls -----
    output$page_controls3 <- renderUI({
        
        req(rv$pdf)
        
        n_max <- pdf_length(rv$pdf$datapath)
        
        div(
            class = "row",
            shiny::sliderInput(
                "page_num3", 
                label = NULL, 
                value = 1, min = 1, max = n_max, step = 1, 
                width = "100%")
        )
        
    })
    
    ### interactive dataset 
    ent_reco_temp<-reactive({
        req(rv$data_prepared_tbl_page)
        
        
        entity_recgnition_page<- rv$data_prepared_tbl_page  %>% filter(page_num==input$page_num3)
        
        entity_recgnition_get_page<-pipeline_entityreco(as.character(entity_recgnition_page$page_text))
        
    })
    
    output$ent_recognition <- renderUI( {
        
            
        HTML(ent_reco_temp())
        #print(entity_recgnition_get_page)
        
    }
        
        )
    
    
    ##------------------------------------------------------------- PAGE 4 --------------------------------------------##
    
    library(tabulizer)
    
    
    runjs('//$("#text-row > div:nth-child(4) > div > div.input-group > input").remove();
        $("#nwediv > div:nth-child(3) > div > div > input").remove()
        //$("#text-row > div:nth-child(4) > div.form-group.shiny-input-container").remove()
        $("#text-row > div:nth-child(4) > div > label").remove()'
    )
    current <- reactiveValues(current=data.frame(V1="", V2="", V3="", V4="", V5=""))#NA)#current=
    
    
    source('drawScrape.R', local=TRUE)
    source('functions.R', local=TRUE)
    
    hide("done"); hide("cancel"); hide("plot"); hide("scrapeRow"); hide("fileDownload")# hide("hot")
    
    pdf <- reactiveValues(pdf_folder = NA,
                          pdfPath = NA,
                          i = "NA",
                          i2 = NA,
                          counter = 0)
    
    tables <- reactiveValues(df=NA)
    safe_GET <- safely(GET)
    assign_extension <- function(response){
        if(is.null(response$result)){
            print("no response")
            # response$result$status_code
            "no response"
        } else{
            if(response$result$status_code==200){
                con_type <- response$result$headers$`content-type`
                if(grepl("pdf", con_type)){
                    ext <- "pdf"
                } else if(grepl("zip", con_type)){
                    ext <- "zip"
                } else if(grepl("html", con_type)){
                    ext <- "html"
                } else {
                    ext <- "other"
                }
                ext
            } else {
                print("bad response")
                response$result$status_code
                # stop()
            }
        }
    }
    ################################################################################################
    
    
    observeEvent(input$downloadButton, {
        req(input$downloadURL)
        showModal(waitingModal())
        url <- input$downloadURL
        pdf$pdf_folder <- "pdf_folder"
        
        
        x <- safe_GET(url)
        
        ext <- assign_extension(x)
        
        
        
        if(ext!='pdf') {
            print("bad extension")
            showNotification("This link does not work!", duration=3, type=c("warning"))
            removeModal()
            req(FALSE)
        }
        
        # if(!file.exists(pdf$pdf_folder)){
        suppressWarnings(dir.create("pdf_folder"))
        # }
        
        temp <- tempfile(fileext = ".pdf", tmpdir = "pdf_folder")
        
        download.file(url, temp, mode = "wb", quiet=TRUE)
        
        addResourcePath("pdf_folder", pdf$pdf_folder)
        
        
        output$pdfOut <- renderUI({
            tags$iframe(src=temp, style=paste0("height:", input$dimension[2],"px; width:100%"))
        })
        
        pdf$pdfPath <- temp
        removeModal()
        show("scrapeRow"); show("hot")
    })
    
    ################################################################################################
    
    observeEvent(input$scrapeButton, {
        pageScrape()
        show("fileDownload")
    })
    
    ################################################################################################
    
    observeEvent(input$drawButton, {
        # show("plot"); hide("pdfOut")
        if(input$pageNumber==""){show("pdfOut"); req(FALSE)}
        selectScrape()
        
    })
    
    observeEvent(input$cancel, {
        hide("plot"); show("pdfOut")
    })
    
    ################################################################################################
    
    observeEvent(input$uploadButton, {
        if (is.null(input$uploadButton)){
            return(NULL)
        }
        
        # pdf$i <- round(runif(1)*10000000)
        # print(pdf$i)
        
        #####
        showModal(waitingModal())
        show("scrapeRow"); show("hot")
        
        
        
        pdf$pdfPath <- input$uploadButton$datapath#paste0("pdf_folder/", pdf$i, ".pdf")
        
        
        
        
        output$pdfOut <- renderUI({
            
            # 
            addResourcePath("pdf_folder",gsub("/0.pdf","",input$uploadButton$datapath))#"pdf_folder")
            
            
            tags$iframe(src=paste0("pdf_folder", "/0.pdf"), style=paste0("height:", input$dimension[2],"px; width:100%"))
            # tags$iframe(src=paste0(input$uploadButton$datapath), style=paste0("height:", input$dimension[2],"px; width:100%"))
        })
        
        
        
        removeModal()
        updateTextInput(session, inputId = "downloadURL", value="")
        
    })
    
    
    
    
    
    ################################################################################################
    
    observe({
        # input$hotButton
        hot = input$hot #isolate(input$hot)#
        if (!is.null(hot)) {
            current$current <- hot_to_r(input$hot)
            
            
        }
    })
    
    output$hot = renderRHandsontable({
        rhandsontable(current$current, useTypes = FALSE) %>%
            hot_table(highlightCol = TRUE, highlightRow = TRUE)
    })
    ################################################################################################
    
    output$fileDownload <- downloadHandler(
        filename = function() {
            paste0("scraped-data", ".csv")
        },
        content = function(file) {
            # current$current <- hot_to_r(input$hot)
            write.csv(current$current, file, row.names = FALSE)
        }
    )
  
    
    session$onSessionEnded(function() { file.remove(file.path(dir(pattern = ".jpg"))) })
  
  
}