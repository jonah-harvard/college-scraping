library(tidyverse)
library(jsonlite)
library(gt)
library(janitor)

testing <- function() {
  "HELLO WORLD"
}


get_professor_data <- function() {
  professors_list <- fromJSON("../professor_ratings_by_college.json")
 
  
  nth_prof <- function(n) {
    
    college_name <- professors_list[n] %>% as_tibble() %>% colnames()
    
    # To avoid errors, separate out the cases where there is and 
    # where there is not data on professor ratings, includes
    # a row of NA values for colleges with no data
    
    if (length(professors_list[[n]]) >= 1) {
      return(professors_list[n] %>% as_tibble() %>% pull(1) %>% mutate(college = college_name))
    } else {
      return(
        tibble(
          name = c(NA_character_), 
          rating = c(NA_integer_), 
          difficulty = c(NA_integer_), 
          department = c(NA_character_), 
          college = c(college_name)
        )
      )
    }
  }
  
  professors = nth_prof(1)
  for (ind in 1:length(professors_list)) {
    if (!is.null(nth_prof(ind))) {
      
      # Rolling together each of the tibbles into one, containing all professor data
      
      professors <- professors %>% union(nth_prof(ind))
    }
  }
  professors <- professors %>% na.omit()
}

basic_plot <- function() {
  professors %>% 
    ggplot(aes(difficulty, rating)) + 
    geom_point() +
    labs(
      title = "Rating as a Function of Difficulty",
      x = "Difficulty",
      y = "Rating"
    ) + 
    theme_classic()
}

plot_facet_wrap <- function() {
  professors %>% 
    ggplot(aes(difficulty, rating, color = department)) + 
    geom_point() + 
    
    # Use geom_smooth to accentuate the relationship between variables
    
    geom_smooth(method = "lm", aes(group = college)) +
    labs(
      title = "Rating as a Function of Difficulty by College",
      x = "Difficulty",
      y = "Rating"
    ) + 
    theme_classic() + 
    theme(legend.position = "none") + 
    facet_wrap(~college) 
}

histogram_of_college <- function(college_name) {
  college_data <- professors %>% filter(college == college_name)
  # print(cor.test(college_data$difficulty, college_data$rating))
  college_data %>% ggplot(aes(rating)) + geom_histogram()
}

# professors %>% ggplot(aes(rating)) + geom_histogram() + labs(title = "Rating by College") #+ facet_wrap(~ college)
# professors %>% ggplot(aes(difficulty)) + geom_histogram() + labs(title = "Difficulty by College") #+ facet_wrap(~ college)


get_salary_data <- function() {
  salaries <- read_csv(
    "../college-salaries/salaries-by-college-type-reduced.csv", 
    na = c("N/A", "NA", NA_character_)
  ) %>% 
    clean_names()
  
  salaries <- salaries %>% mutate(
    school_name = map_chr(school_name, ~str_remove(., " \\(\\w*\\)")),
    starting_median_salary = map_dbl(starting_median_salary, ~ as.numeric(str_remove_all(., "[$,]"))),
    mid_career_median_salary = map_dbl(mid_career_median_salary, ~ as.numeric(str_remove_all(., "[$,]"))),
    mid_career_10th_percentile_salary = map_dbl(mid_career_10th_percentile_salary, ~ as.numeric(str_remove_all(., "[$,]"))),
    mid_career_25th_percentile_salary = map_dbl(mid_career_25th_percentile_salary, ~ as.numeric(str_remove_all(., "[$,]"))),
    mid_career_75th_percentile_salary = map_dbl(mid_career_75th_percentile_salary, ~ as.numeric(str_remove_all(., "[$,]"))),
    mid_career_90th_percentile_salary = map_dbl(mid_career_90th_percentile_salary, ~ as.numeric(str_remove_all(., "[$,]")))
  )
}

plot_with_salary <- function() {
  professors %>% inner_join(salaries, by=c("college" = "school_name")) %>% 
    ggplot(aes(difficulty, rating, color = starting_median_salary)) + geom_point()
}

plot_with_salary_facet_wrap <- function() {
  professors %>% inner_join(salaries, by=c("college" = "school_name")) %>% 
    ggplot(aes(difficulty, rating, color = starting_median_salary)) + geom_point() + facet_wrap(~starting_median_salary)
}