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
library(GGally)
library(ggpubr)
library(lubridate)

grad_data             <- read_csv("filecache/grad_programs_data.csv")
metadata              <- read_csv("filecache/grad_programs_metadata.csv")
program_codes_top     <- read.csv("filecache/top_program_codes_grad.csv")
program_codes_sub     <- read.csv("filecache/sub_program_codes_grad_by_level.csv")


grad_comparison        <- read.csv("filecache/grad_comparison.csv")
grad_comparison_fields <- read.csv("filecache/grad_comparison_fields.csv")

function(input, output, session) {
    # prep the data using reactives:
    All_in_top_program_code <- reactive({
        # All_in_top_program_code <- function(){
        grad_data |> dplyr::filter(Field.of.study.parent == input$program)  |>
            dplyr::filter(Program.type == input$Degree) |>
            dplyr::filter(VALUE2012>input$minvalue2012)
    })
    Baseline_uni <- reactive({
        # Baseline_uni <- function(){
        All_in_top_program_code() |> dplyr::filter(GEO == input$baselineuni)   
    })
    national <- reactive({
        # national <- function(){
        All_in_top_program_code() |> dplyr::filter(GEO == "Canada")   
    })
    grad_comp <- reactive({
        # grad_comp <- function(){
        grad_comparison |> dplyr::filter(Field.of.study.parent == input$program) |>
            mutate(Date = as_date(Date))
    })
    grad_subfields <- reactive({
        # grad_subfields <- function(){
        if(input$onlyblacklineplots == TRUE){
            grad_comp() |> 
                dplyr::filter(GEO == input$baselineuni)   |>
                pull(Field.of.study )|> unique()    
        }else{
            grad_comp() |> pull(Field.of.study )|> unique()    
        }
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
    #     program_codes_sub |> dplyr::filter(Field.of.study.parent == input$program)
    # }
    subfields <- reactive({
        # subfields <- function(){
        program_codes_sub |> 
            dplyr::filter(Field.of.study.parent == input$program)|> 
            pull(Field.of.study) |> 
            unique()
    })
    PlotHeight <- reactive({
        #  PlotHeight <- function(){
        length(baseline_subfields())*200
         })
    PlotHeightGrad <- reactive({
        #  PlotHeight <- function(){
        length(grad_subfields())*200
    })
    
    output$distPlot <- renderPlot(height = function(){PlotHeight()},{
        # Make the plot
               p =  ggplot()
               
               
               if(input$relative == TRUE){
                    if(input$shownational==TRUE){
                     #national:
                      p =p+geom_line(data =  national()|>
                                   dplyr::filter(Field.of.study %in% baseline_subfields()),
                               aes(x = Date, y = VALUE), colour = "red",  alpha = 1, lwd = 2) 
                    }
                  # the whole enchillada:
                  p = p+ geom_line(data =  All_in_top_program_code() |>
                                 dplyr::filter(GEO != "Canada")|>
                                     dplyr::filter(Field.of.study %in% baseline_subfields()),
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
                                   dplyr::filter(Field.of.study %in% baseline_subfields()),
                                   aes(x = Date, y = Percent_growth_since_2012), colour = "red",  alpha = 1, lwd = 2) 
                }
                # the whole enchillada:
                p = p+ geom_line(data =  All_in_top_program_code() |>
                                     dplyr::filter(Field.of.study %in% baseline_subfields())|>
                                     dplyr::filter(GEO != "Canada"),
                                 aes(x = Date, y = Percent_growth_since_2012, colour=School),
                                 alpha = .4, lwd = 2)+
                    # school to highlight:
                    geom_line(data = Baseline_uni(),
                              aes(x = Date, y = Percent_growth_since_2012), colour = "black",  alpha = .6, lwd = 2)+
                    ylab("Graduates as a Percent of Their 2012 Value")+
                    theme(text=element_text(size=20))+
                    facet_wrap(~Field.of.study, scales = "free", nrow =length(subfields()) )
            }
        return(p)
    })
    
    output$grad_ugrad <- renderPlot(height = function(){PlotHeightGrad()},{
        # Make the plot
        p =  ggplot()
        if(input$shownational==TRUE){
            #national:
            p = p + geom_point(
                data = grad_comp() |> 
                    dplyr::filter(REF_DATE >= min(input$year_of_ref) & REF_DATE <= max(input$year_of_ref)) |>
                    dplyr::filter(Field.of.study %in% grad_subfields())  |> 
                    dplyr::filter(GEO == "Canada"),
                aes(x=Undergraduate.program, y = all_grad_programs), 
                colour = "red",  
                alpha = 1) 
        }
        # the whole enchillada:
        p =p+
            geom_point(data = grad_comp() |> 
                           dplyr::filter(Field.of.study %in% grad_subfields())  |> 
                           dplyr::filter(REF_DATE >= min(input$year_of_ref) & REF_DATE <= max(input$year_of_ref)) |>
                           dplyr::filter(GEO != "Canada"),
                       aes(x=Undergraduate.program, y = all_grad_programs, colour = School, size = REF_DATE), 
                       alpha = .3, lwd = 2) 
        
        # school to highlight:
        p =p+
            geom_point(data = grad_comp() |> 
                           dplyr::filter(Field.of.study %in% grad_subfields())  |> 
                           dplyr::filter(REF_DATE >= min(input$year_of_ref) & REF_DATE <= max(input$year_of_ref)) |>
                           dplyr::filter(GEO == input$baselineuni),
                       aes(x=Undergraduate.program, y = all_grad_programs, size = REF_DATE), 
                       colour = "black",  alpha = .6)+
            # geom_line(data = grad_comp() |> 
            #               dplyr::filter(REF_DATE >= min(input$year_of_ref) & REF_DATE <= max(input$year_of_ref)) |>
            #                dplyr::filter(Field.of.study %in% grad_subfields())  |> 
            #                dplyr::filter(GEO == input$baselineuni),
            #            aes(x=Undergraduate.program, y = all_grad_programs), 
            #            colour = "black",  alpha = .6)+
            theme(text=element_text(size=20))+
            facet_wrap(~Field.of.study, scales = "free", nrow =length(grad_subfields()) )
        
        return(p)
    })
    
    
    
    
    
    
}
