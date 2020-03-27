library(shiny)
source("./analysis_functions.R")

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("How Students Rate Their Professors Across US Campusus"),
    plotOutput("basic"),
    plotOutput("facet_wrap_college")
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
