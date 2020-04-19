library(shiny)
library(shinythemes)
source("./analysis_functions.R")

# Define UI for application that draws a histogram
ui <- navbarPage(
    theme = shinytheme("flatly"),
    "Professor Ratings Across America",
    tabPanel(
        "Exploratory Analysis",
        tabsetPanel(
            tabPanel(
                "Basic Plot", 
                h3("Rating vs. Difficulty"),
                plotOutput("basic"),
                p("The initial graphing of the data doesn't seem to convey much.
                  By all appearances, there could be very little correlation between difficulty and rating.
                  We must continue our exploration to make any conclusions."),
            ), 
            tabPanel(
                "Facet Wrapped",
                plotOutput("facet_wrap_college"),
                p("Faceting by college makes the negative correlation much clearer in certain colleges.")
            )
        )
    
        ),
    tabPanel(
        "About",
        fluidPage(
            includeMarkdown("about.md")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) { 
    professors <- get_professor_data()
    
    output$basic <- renderPlot({
        basic_plot(professors)
    })
    
    output$facet_wrap_college <- renderPlot({
        plot_facet_wrap(professors)
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
