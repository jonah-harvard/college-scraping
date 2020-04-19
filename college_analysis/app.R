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
                "Distribution (Rating)", 
                h3("Distibution of Professor Rating Scores"),
                plotOutput("dist_ratings"),
                p("While we might expect a pretty normal distribution of ratings,
                the distribution of ratings is heavily skewed left. I think that this is because people don't want
                  to rate other people badly, so scores gravitate between 3 and 5 and shy away from 1 and 2.")
            ),
            tabPanel(
                "Distribution (Difficulty)", 
                h3("Distribution of Professor Difficulty Scores"),
                plotOutput("dist_difficulties"),
                p("Here the data seems to be much more normally distributed. I would guess that this is because
                  people do not have as much trouble saying that a professor is very difficult or very easy as they do 
                  saying that a professor is very bad, which doesn't create that same reporting bias. ")
            ),
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
        "Inferential Analysis",
        tabsetPanel(
            tabPanel(
                "Correlation (Rating Vs. Difficulty)",
                p(
                    "(The interval might take a moment to appear as we bootstrap 1000 samples).
                    Using the boot strapping quantile method for generating a 
                    confidence interval, we calculate a 
                    95% confidence interval for the correlation between 
                    rating and difficulty. The confidence interval is: ",
                  textOutput("diff_cor"),
                  "This means that we can be quite secure in saying that our correlation, 
                  while not large in magnitude, is very likely negative. This means that 
                  we can be relatively sure that our data suggests a negative association
                  between difficulty and rating. This supports our hypothesis that 
                  professor rating is negatively correlated with difficulty."
                )
            ), 
            tabPanel(
                "Relationship (Rating Vs. Difficulty)",
                gt_output("relationship_diff"),
                p("Using a linear model, we can look at the predicted average relationship between difficulty and rating.
                  In particular, if we are going to use a Bayesian interpretation of this confidence interval, we can 
                  say that there is a 95% chance that the true coefficient is between our upper and lower bound. This means
                  we can be fairly sure that we can expect on average that if professor A has difficulty 1 point higher than 
                  professor B, then professor A will have a rating between .33 and .23 points less than professor B.")
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
    
    output$dist_ratings <- renderPlot({
        dist_rating(professors)
    })
    
    output$dist_difficulties <- renderPlot({
        dist_difficulty(professors)
    })
    
    output$basic <- renderPlot({
        basic_plot(professors)
    })
    
    output$facet_wrap_college <- renderPlot({
        plot_facet_wrap(professors)
    })
    
    output$diff_cor <- renderText({calculate_cor(professors)})
    
    output$relationship_diff <- render_gt({plot_lm(professors)})
}

# Run the application 
shinyApp(ui = ui, server = server)
