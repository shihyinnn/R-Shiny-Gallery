library(shiny)

shinyUI(fluidPage(
    titlePanel("Health Insurance - Monthly Premium"),
    
    sidebarLayout(
        sidebarPanel(
            helpText("Select a year to examine."),
            
            selectInput("var", 
                        label = "Choose a variable to display",
                        choices = list("2014", "2015", "2016"),
                        selected = "2015"),
            
            selectInput("var2",
                        label = "Choose a variable to display",
                        choices = list("Median", "Mean"),
                        selected = "Median")
        ),
        
        mainPanel(
            tabsetPanel(
                tabPanel("Plot", plotOutput("plot")), 
                tabPanel("Summary", verbatimTextOutput("summary")), 
                tabPanel("Table", tableOutput("table"))
            )
        )
    )))