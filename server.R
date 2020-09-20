#### Testing Area ####
# # Inputs
# days = 300
# initialinventory = 20
# restockProb = "30%"
# restockAmt = 5
# distribution = "Poisson"
# randomSeed = 533
# 
# # Initialize vectors
# set.seed(randomSeed)
# beginningofday = rep(0, days)
# endofday = rep(0, days)
# demands = sample(0:8, size = days, replace = TRUE) # Need to change based on dist.
# restockProbs = c(as.numeric(str_remove(restockProb, "%")))
# restockProbs[2] = 100 - restockProbs[1]
# restock = sample(c(restockAmt, 0), size = days, replace = TRUE, prob = restockProbs)
# missed = rep(0, days)
# 
# beginningofday[1] = initialinventory
# for(i in 1:days){
#     if(demands[i] > beginningofday[i]){
#         missed[i] = demands[i]-beginningofday[i]
#         endofday[i] = 0
#     } else{
#         endofday[i] = beginningofday[i] - demands[i]
#     }
# 
#     beginningofday[i+1] = endofday[i] + restock[i]
# }


#### Shiny Server ####
shinyServer(function(input, output, session) {
    
    SIMULATION = reactive({
        set.seed(input$randomSeed)
        beginningofday = rep(0, input$days+1)
        endofday = rep(0, input$days)
        
        if(input$distribution == "Poisson (average is 4)"){
            demands = rpois(input$days, lambda = 4)
        } else if(input$distribution == "Uniform (0-8)"){
            demands = sample(0:8, size = input$days, replace = TRUE)
        } else if (input$distribution == "Uniform (3-5)"){
            demands = sample(3:5, size = input$days, replace = TRUE)
        }
        
        restockProbs = c(as.numeric(str_remove(input$restockProb, "%")))
        restockProbs[2] = 100 - restockProbs[1]
        restock = sample(c(input$restockAmt, 0), size = input$days, replace = TRUE, prob = restockProbs)
        missed = rep(0, input$days)
        
        beginningofday[1] = input$initialinventory
        for(i in 1:input$days){
            if(demands[i] > beginningofday[i]){
                missed[i] = demands[i]-beginningofday[i]
                endofday[i] = 0
            } else{
                endofday[i] = beginningofday[i] - demands[i]
            }
            
            beginningofday[i+1] = endofday[i] + restock[i]
        }
        
        df = data.frame(Day      = 1:input$days,
                        BegOfDay = head(beginningofday, -1),
                        EndOfDay = endofday,
                        Missed   = missed)
        
        return(df)
    })

    chosenTheme = reactive(eval(parse(text = input$plotsTheme)))
    
    output$timePlot = renderPlotly({
        metric = input$timeMetric
        ylabel = case_when(
            metric == "BegOfDay" ~ "Beginning of Day Stock",
            metric == "EndOfDay" ~ "End of Day Stock",
            metric == "Missed"   ~ "Missed Demand Value"
        )
        
        plot = SIMULATION() %>%
            ggplot(aes(x = Day, y = get(metric),
                       text = glue("Day: {Day}
                                    Value: {get(metric)}"))) +
            geom_path(group = 1) +
            labs(title = glue("{ylabel} Trends"), x = "Day", y = ylabel) +
            chosenTheme()()
            
        ggplotly(plot, tooltip = "text")
    })
    
    output$distPlot = renderPlot({
        metric = input$distMetric
        xlabel = case_when(
            metric == "BegOfDay" ~ "Beginning of Day",
            metric == "EndOfDay" ~ "End of Day",
            metric == "Missed"   ~ "Missed Demand"
        )
        
        plot = SIMULATION() %>%
            ggplot(aes(x = get(metric))) +
            geom_histogram(bins = input$numBins, fill = "lightgray", color = "black") + 
            labs(title = glue("Histogram of Values - {xlabel}"), x = xlabel, y = "Count") +
            chosenTheme()()
        
        plot
    })
    
    output$summaryStats = DT::renderDataTable({
        summary(SIMULATION()$BegOfDay)
        table = SIMULATION() %>%
            pivot_longer(cols = BegOfDay:Missed, names_to = "Measure") %>%
            group_by(Measure) %>%
            summarize(`Min.`    = min(value),
                      `1st Qu.` = quantile(value, .25),
                      Median    = median(value),
                      Mean      = mean(value, na.rm = TRUE),
                      `3rd Qu.` = quantile(value, .75),
                      `Max.`    = max(value)) %>%
            mutate(Measure = case_when(
                Measure == "BegOfDay" ~ "Beginning of Day",
                Measure == "EndOfDay" ~ "End of Day",
                Measure == "Missed"   ~ "Missed Demand"
            ))
        
        DT::datatable(table,
                      rownames = FALSE,
                      caption = "Simulation Summary Statistics",
                      style = "bootstrap")
    })
    
    output$simulationTable = DT::renderDataTable({
        DT::datatable(SIMULATION(), 
                      rownames = FALSE,
                      caption = "Simulation Results",
                      style = "bootstrap")
    })
})
