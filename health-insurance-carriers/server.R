# server.R

library(ggplot2)
library(dplyr)
library(maps)
library(scales)
library(ggthemes)
# source("helpers.R")
rate <- readRDS("data/rate.rds")
# beneCost <- readRDS("data/BenefitsCostSharing.rds")
# small.rate <- head(rate, 1000000)
# small.rate <- readRDS("data/smallRate.rds")

shinyServer(function(input, output) {
    
    rate.year <- reactive({  
        subset(rate, (rate$BusinessYear == input$var & 
                          rate$IndividualRate != 999999),
               select = c(BusinessYear:IndividualTobaccoRate))
    })
    
    stateCounts <- reactive({
        rate.year() %>%
            select(StateCode, IssuerId, PlanId, IndividualRate) %>% 
            group_by(StateCode) %>%
            summarize(Carriers = length(unique(IssuerId)), 
                      PlanAvailable = length(unique(PlanId)),
                      MeanIndRate= mean(IndividualRate),
                      MedianIndRate = median(IndividualRate)) %>%
            arrange(desc(PlanAvailable))
    })
    
     stateCounts_carriers <- reactive({
         stateCounts() %>%
             mutate(CarriersGroup = ifelse(Carriers < 15, "(0,15)",
                           ifelse(Carriers<25,
                                  "[15,25)","[25,35)")))

     })
    
    output$plot <- renderPlot({
        ggplot(stateCounts_carriers(), aes(x=reorder(StateCode, PlanAvailable), y=PlanAvailable)) +
            geom_bar(aes(fill = CarriersGroup), stat="identity") +
            coord_flip() +
            ggtitle("Carriers vs. Plans Available By State") +
            labs(x="State", y="Plans Available")
    })
    
    # Generate a summary of the data
    output$summary <- renderPrint({
        summary(stateCounts_carriers())
    })

    # Generate an HTML table view of the data
    output$table <- renderTable({
        data.frame(x=stateCounts_carriers())
    })
})