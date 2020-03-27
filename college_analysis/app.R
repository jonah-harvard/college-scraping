library(shiny)
source("../analysis_functions.R")

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("How Students Rate Their Professors Across US Campusus"),
    textOutput("test")
)

# Define server logic required to draw a histogram
server <- function(input, output) {

    output$test <- renderPlot({
        testing()
    })
}

# Run the application 
shinyApp(ui = ui, server = server)
