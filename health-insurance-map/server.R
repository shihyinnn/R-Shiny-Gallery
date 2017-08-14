# server.R

library(ggplot2)
library(dplyr)
library(maps)
library(scales)
library(ggthemes)

# source("helpers.R")
rate <- readRDS("data/rate.rds")
us_map = map_data('state')
statename <- group_by(us_map, region) %>% 
    summarise(long = mean(long), lat = mean(lat))
statename$region.abb <- state.abb[match(statename$region,tolower(state.name))]

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
    
    
    stateCounts_region <- reactive({
        stateCounts() %>%
            mutate(region = tolower(
                state.name[match(StateCode, state.abb)]))

    })
    
    mergeMap <- reactive({
        left_join(stateCounts_region(), us_map, by="region")
    })
    
    
    output$plot <- renderPlot({
        if(input$var2 == "Median"){
            geom <- geom_polygon(data=mergeMap(), aes(x=long, y=lat, group = group, fill=MedianIndRate))
            lab <- labs(fill = "Median Premium $/mon", title = "Median Monthly Premium Distribution", x="", y="")
        }else{
            geom <- geom_polygon(data=mergeMap(), aes(x=long, y=lat, group = group, fill=MeanIndRate))
            lab <- labs(fill = "Average Premium $/mon", title = "Average Monthly Premium Distribution", x="", y="")
        }
        ggplot() + 
            geom +
            lab +
            scale_fill_continuous(low = "thistle2", high = "darkblue", guide="colorbar") +
            theme_bw() +
            scale_y_continuous(breaks=c()) + 
            scale_x_continuous(breaks=c()) + 
            theme(panel.border =  element_blank()) + 
            geom_text(data=statename, aes(x=long, y=lat, label=region.abb), na.rm = T, size=2) +
            coord_map()
        
    })
    
    # Generate a summary of the data
    output$summary <- renderPrint({
        summary(stateCounts())
    })

    # Generate an HTML table view of the data
    output$table <- renderTable({
        data.frame(x=stateCounts_region())
    })
})