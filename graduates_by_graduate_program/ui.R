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
library(GGally)
library(ggpubr)
library(lubridate)
doctoral_universities      <- read.csv("filecache/doctoral_list.csv")[,2]
comprehensive_universities <- read.csv("filecache/comprehensive_list.csv")[,2]
program_codes_top          <- read.csv("filecache/sub_program_codes_grad_by_level.csv")|> select(Field.of.study.parent)|> unique()

# for testing:
# input = list()
# input$program = "Computer and information sciences and support services [11]"
# input$baselineuni = "Carleton University, Ontario"
# input$minvalue2012 = 0
# input$onlyblacklineplots = TRUE
# input$relative = FALSE
# input$shownational = TRUE
# input$Degree = "Graduate program (third cycle)"

# Define UI for application that draws a histogram
fluidPage(

    # Application title
    titlePanel("Graduates per Program per Year"),
    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            HTML("View the code on <a href='https://github.com/iamdavecampbell/graduates_by_program/tree/main' target = '_blank'>Github</a><br><br>"),
            selectInput("program",
                        "Program of interest:",
                        choices = program_codes_top, 
                        selected = "Mathematics and statistics [27]")
        ,
        radioButtons("Degree", "Degree",
                     choices = c("Masters" = "Graduate program (second cycle)" , 
                                 "PhD" =  "Graduate program (third cycle)"), selected = "Graduate program (second cycle)"),
        selectInput("baselineuni",
                    "Baseline University for Comparison (black line)",
                    choices = c(
                        sort(c(doctoral_universities,comprehensive_universities))
                    ),
                    selected = "Carleton University, Ontario"
    ),
    
    radioButtons("shownational", "Show National (red line)",
                 choices = c("yes" = TRUE, "no" = FALSE), selected = FALSE),
    radioButtons("onlyblacklineplots", "Show only programs reported by the baseline university",
                 choices = c("yes" = TRUE, "no" = FALSE), selected = TRUE)
    ),
    
        # Show a plot of the generated distribution
        mainPanel(
            h2("Postsecondary graduates (Masters and PhD), by detailed field of study, institution, and program and student characteristics"),
            h4("From Cansim table: 37-10-0235"),
            tabsetPanel(type = "tabs",
                        tabPanel("Graduates Per Program",
                                 h4("Instructions:"),
                                 p("Subjects are hierarchical, select a top level ",strong("Program of interest"),"to plot all subgroups. Choose a baseline university to highlight using the dropdown menu ", 
                                   strong("Baseline University for Comparison (black line)"),"."),
                                 radioButtons("relative", "Values to plot",
                                              choices = c("Graduate count" = TRUE, "Percentage of 2012 value" = FALSE), selected = FALSE),
                                   p("If the ", strong("Values to plot"), " are percentages of the 2012, consider using the ", 
                                   strong("Show National (red line)"),
                                   " to include the change in the national value.  But skip this if showing the counts of graduates since the national count of graduates is always really big compared to the individual universities.",
                                   "  To focus in on what is reported by the baseline university, use the button ", strong("Show only programs reported by the baseline university"),"."),
                                 p("Variability is really high when a school has few graduates.  Consider removing the smaller departments by adjusting the threshold slider in ",
                                   strong("Plot Universities with at least this number of graduates in 2012"),"."),
                                 sliderInput("minvalue2012",
                                             "Plot Universities with at least this number of graduates in 2012",
                                             min = 0,
                                             max = 10,
                                             value = 1),
                                 p(strong("If you see an error instead of a plot"),
                                   ", move the slider to the left.  The ", 
                                   strong("Baseline University"),
                                   " had few graduates in 2012."),
                                 plotOutput("distPlot", width = "100%")
                                 
                                 ),
                        tabPanel("Graduates vs Undergraduates",
                                 h4("Instructions:"),
                                 p("Subjects are hierarchical, select a top level ",strong("Program of interest"),"to plot all subgroups. Choose a baseline university to highlight using the dropdown menu ", 
                                   strong("Baseline University for Comparison (black line)"),".  Consider using the ", 
                                   strong("Show National (red line)"),
                                   " to include the change in the national value.  But skip this if showing the counts of graduates since the national count of graduates is always really big compared to the individual universities.",
                                   "  To focus in on what is reported by the baseline university, use the button ", strong("Show only programs reported by the baseline university"),"."),
                                 sliderInput("year_of_ref",
                                             "Plot just these years",
                                             min = 2009,
                                             max = 2021,
                                             value = c(2019,2021),
                                             dragRange = TRUE),
                                 plotOutput("grad_ugrad", width = "100%")
                                 
                        ),
                        tabPanel("Notes about the data", 
                                 p("Stat Can gathers the data using the Postsecondary Student Information System (PSIS) including information about changes of programs, completion rates, etc... from every institution."),
                                 HTML("Values are randomized by <a href='https://www.statcan.gc.ca/en/statistical-programs/instrument/5017_Q1_V8' target='_blank'>Stat Can</a><br>"),
                                 em("' All counts are randomly rounded to a multiple of 3 using the following procedure: counts which are already a multiple of 3 are not adjusted; counts one greater than a multiple of 3 are adjusted to the next lowest multiple of 3 with a probability of two-thirds and to the next highest multiple of 3 with a probability of one-third. The probabilities are reversed for counts that are one less than a multiple of 3.'"),
                                 p("Note that only a student’s major is reported.  They don’t seem to track minors.  It isn’t clear how double majors are counted.  It’s probably just a pick one solution. "),
                                 p("Data Science may be hidden because it may be run through Statistics and/or Comp Sci departments (or others), so it will likely be listed by the home department."),
                                 p(" The legend shows the school names, but names use a 'rule based' truncation that may produce artifacts, one notable example is that Université Laval is 'Univ al'.")
                        )
            )
            
        )
    )
)
