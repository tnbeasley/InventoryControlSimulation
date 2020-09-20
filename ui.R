
library(shiny)
library(shinyWidgets)
library(shinydashboard)
library(shinydashboardPlus)

library(tidyverse)
library(glue)

library(plotly)
library(ggthemes)

header = dashboardHeader(
    title = "Tanner Beasley Inventory Control Simulation",
    titleWidth = 400
)

sidebar = dashboardSidebar(
    sliderInput(
        inputId = "days",
        label = "Number of days",
        value = 100,
        min = 30,
        max = 365
    ),
    
    sliderInput(
        inputId = "initialinventory",
        label = "Initial inventory",
        value = 20,
        min = 0,
        max = 100
    ),
    
    sliderTextInput(
        inputId = "restockProb",
        label = "Probability of overnight restock",
        choices = paste0(seq(1, 99, by = 1), "%"),
        selected = "30%"
    ),
    
    sliderInput(
        inputId = "restockAmt",
        label = "Restock amount",
        value = 6,
        min = 1,
        max = 20
    ),
    
    prettyRadioButtons(
        inputId = "distribution",
        label = "Probability distribution for demand",
        choices = c("Poisson (average is 4)", "Uniform (0-8)", "Uniform (3-5)"),
        selected = "Poisson (average is 4)"
    ),
    
    numericInput(
        inputId = "randomSeed",
        label = "Random # seed",
        value = 533,
        min = 1,
        max = 99999,
        step = 1
    ),
    
    hr(),
    
    selectInput(
        inputId = "plotsTheme",
        label = "Plots theme",
        choices = sort(c("theme_minimal",str_subset(ls("package:ggthemes"), "theme_"))),
        selected = "theme_minimal"
    )
)

body = dashboardBody(
    tabsetPanel(
        tabPanel(
            title = "Trends",
            icon = icon("chart-line"),
            prettyRadioButtons(
                inputId = "timeMetric",
                label = "Metric",
                choiceNames = c("Beg. of day", "End of day", "Missed demand"),
                choiceValues = c("BegOfDay", "EndOfDay", "Missed"),
                inline = TRUE
            ),
            
            plotlyOutput("timePlot")
        ),
        
        tabPanel(
            title = "Distributions",
            icon = icon("chart-area"),
            fluidRow(
                column(
                    width = 6,
                    prettyRadioButtons(
                        inputId = "distMetric",
                        label = "Metric",
                        choiceNames = c("Beg. of day", "End of day", "Missed demand"),
                        choiceValues = c("BegOfDay", "EndOfDay", "Missed"),
                        inline = TRUE
                    )
                ),
                
                column(
                    width = 6,
                    sliderInput(
                        inputId = "numBins",
                        label = "# of bins",
                        value = 15,
                        min = 1,
                        max = 30
                    )
                )
            ),
            
            plotOutput("distPlot")
        ),
        
        tabPanel(
            title = "Data",
            icon = icon("table"),
            DT::dataTableOutput("summaryStats"),
            hr(), hr(),
            DT::dataTableOutput("simulationTable")
        )
    )
)

dashboardPage(header, sidebar, body)