#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
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
doctoral_universities      <- read.csv("filecache/doctoral_list.csv")[,2]
comprehensive_universities <- read.csv("filecache/comprehensive_list.csv")[,2]
program_codes_top          <- read.csv("filecache/top_program_codes.csv")

# for testing:
# input = list()
# input$program = "Mathematics and statistics [27]"
# input$baselineuni = "Carleton University, Ontario"
# input$minvalue2012 = 4
# input$onlyblacklineplots = TRUE
# input$relative = FALSE

# Define UI for application that draws a histogram
fluidPage(

    # Application title
    titlePanel("Graduates per Program per Year"),
    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            selectInput("program",
                        "Program of interest:",
                        choices = program_codes_top, 
                        selected = "Mathematics and statistics [27]")
        ,
        selectInput("baselineuni",
                    "Baseline University for Comparison (black line)",
                    choices = c(
                        sort(c(doctoral_universities,comprehensive_universities))
                    ),
                    selected = "Carleton University, Ontario"
    ),
    radioButtons("relative", "Values to plot",
                 choices = c("Graduate count" = TRUE, "Percentage of 2012 value" = FALSE), selected = FALSE),
    radioButtons("shownational", "Show National (red line)",
                 choices = c("yes" = TRUE, "no" = FALSE), selected = FALSE),
    radioButtons("onlyblacklineplots", "Show only programs reported by the baseline university",
                 choices = c("yes" = TRUE, "no" = FALSE), selected = TRUE),
    sliderInput("minvalue2012",
                "Plot Universities with at least this number of graduates in 2012",
                min = 0,
                max = 30,
                value = 10)
    ),
    
        # Show a plot of the generated distribution
        mainPanel(
            h2("Postsecondary graduates, by detailed field of study, institution, and program and student characteristics"),
            p("From Cansim table: 37-10-0235"),
            h4("Instructions:"),
            p("Subjects are hierarchical, select a top level ",strong("Program of interest"),"to plot all subgroups. Choose a baseline university to highlight using the dropdown menu ", 
              strong("Baseline University for Comparison (black line)"),".  If the ", strong("Values to plot"), " are percentages of the 2012, consider using the ", 
              strong("Show National (red line)"),
              " to include the change in the national value.  But skip this if showing the counts of graduates since the national count of graduates is always really big compared to the individual universities.",
              "  To focus in on what is reported by the baseline university, use the button ", strong("Show only programs reported by the baseline university"),"."),
              p("Variability is really high when a school has few graduates.  Consider removing the smaller departments by adjusting the threshold slider in ",
                strong("Plot Universities with at least this number of graduates in 2012"),
                ". The legend shows the school names, but names use a 'rule based' truncation that may produce artifacts, one notable example is that Université Laval is 'Univ al'."),

            plotOutput("distPlot", width = "100%")

        )
    )
)
