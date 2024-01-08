#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)
library(cansim)
library(GGally)
library(ggpubr)
library(lubridate)

undergrad_data             <- read_csv("filecache/undergrad_programs_data.csv")
metadata                   <- read_csv("filecache/undergrad_programs_metadata.csv")
program_codes_top          <- read.csv("filecache/top_program_codes.csv")
program_codes_sub          <- read.csv("filecache/sub_program_codes.csv")


function(input, output, session) {
    # prep the data using reactives:
    All_in_top_program_code <- reactive({
        # All_in_top_program_code <- function(){
        undergrad_data |> filter(Field.of.study.parent == input$program)  |>
            filter(VALUE2012>input$minvalue2012)
    })
    Baseline_uni <- reactive({
        # Baseline_uni <- function(){
        All_in_top_program_code() |> filter(GEO == input$baselineuni)   
    })
    national <- reactive({
        # national <- function(){
        All_in_top_program_code() |> filter(GEO == "Canada")   
    })
    
    baseline_subfields <- reactive({
        # baseline_subfields <- function(){
        if(input$onlyblacklineplots == TRUE){
            Baseline_uni()            |> pull(Field.of.study )|> unique()
        }else{
            All_in_top_program_code() |> pull(Field.of.study )|> unique()    
        }
    })
    # subfield_codes <- reactive(){
    #     program_codes_sub |> filter(Field.of.study.parent == input$program)
    # }
    subfields <- reactive({
        # subfields <- function(){
        program_codes_sub |> 
            filter(Field.of.study.parent == input$program)|> 
            pull(Field.of.study) |> 
            unique()
    })
    PlotHeight <- reactive({
        #  PlotHeight <- function(){
        length(baseline_subfields())*200
         })
    
    output$distPlot <- renderPlot(height = function(){PlotHeight()},{
        # Make the plot
               p =  ggplot()
               
               
               if(input$relative == TRUE){
                    if(input$shownational==TRUE){
                     #national:
                      p =p+geom_line(data =  national()|>
                                   filter(Field.of.study %in% baseline_subfields()),
                               aes(x = Date, y = VALUE), colour = "red",  alpha = 1, lwd = 2) 
                    }
                  # the whole enchillada:
                  p = p+ geom_line(data =  All_in_top_program_code() |>
                                 filter(GEO != "Canada")|>
                                     filter(Field.of.study %in% baseline_subfields()),
                             aes(x = Date, y = VALUE, colour=School),
                             alpha = .4, lwd = 2)+
                 # school to highlight:
                 geom_line(data = Baseline_uni(),
                             aes(x = Date, y = VALUE), colour = "black",  alpha = .6, lwd = 2)+
                      theme(text=element_text(size=20))+
                facet_wrap(~Field.of.study, scales = "free", nrow =length(subfields()) )
            }else{ # work with relative growth rather than counts
                if(input$shownational==TRUE){
                    #national:
                    p =p+geom_line(data =  national()|>
                                   filter(Field.of.study %in% baseline_subfields()),
                                   aes(x = Date, y = Percent_growth_since_2012), colour = "red",  alpha = 1, lwd = 2) 
                }
                # the whole enchillada:
                p = p+ geom_line(data =  All_in_top_program_code() |>
                                     filter(Field.of.study %in% baseline_subfields())|>
                                     filter(GEO != "Canada"),
                                 aes(x = Date, y = Percent_growth_since_2012, colour=School),
                                 alpha = .4, lwd = 2)+
                    # school to highlight:
                    geom_line(data = Baseline_uni(),
                              aes(x = Date, y = Percent_growth_since_2012), colour = "black",  alpha = .6, lwd = 2)+
                    theme(text=element_text(size=20))+
                    facet_wrap(~Field.of.study, scales = "free", nrow =length(subfields()) )
            }
        return(p)
    })
    
}
