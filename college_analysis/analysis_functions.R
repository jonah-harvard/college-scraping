library(tidyverse)
library(jsonlite)
library(gt)
library(janitor)
library(infer)
library(broom)

get_professor_data <- function() {
  professors_list <- fromJSON("./professor_ratings_by_college.json")
 
  
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
  professors
}

basic_plot <- function(professors) {
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


plot_facet_wrap <- function(professors) {
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

calculate_cor <- function(professors) {
  boot_strap <- rep_sample_n(professors, size = nrow(professors), replace = TRUE, reps = 1000)
  cors <- boot_strap %>% 
    group_by(replicate) %>% 
    summarise(rating_difficulty_cor = cor(rating, difficulty)) %>% 
    pull(rating_difficulty_cor)
  upper <- cors %>% quantile(.975)
  lower <- cors %>% quantile(.025)
  paste0("(", round(lower, 3), ", ", round(upper, 3), ")")
}

plot_lm <- function(professors) {
  college_model <- lm(rating ~ difficulty, data =  professors)
  college_model %>% 
    tidy(conf.int = T) %>% 
    select(
      "Variable" = term,
      "Estimate" = estimate,
      "Lower bound" = conf.low,
      "Upper bound" = conf.high
    ) %>% 
    gt() %>% 
    tab_header(
      title = "Effect of Difficulty on Rating"
    ) %>% 
    fmt_number(
      columns = vars("Estimate", "Lower bound", "Upper bound")
    )
}


histogram_of_college <- function(professors, college_name) {
  college_data <- professors %>% filter(college == college_name)
  # print(cor.test(college_data$difficulty, college_data$rating))
  college_data %>% ggplot(aes(rating)) + geom_histogram()
}

dist_rating <- function(professors) {
  professors %>% 
    ggplot(aes(rating)) + 
    geom_histogram() + 
    theme_classic() + 
    labs(
      y = "Count",
      x = "Rating"
    ) 
}

dist_difficulty <- function(professors) {
  professors %>% 
    ggplot(aes(difficulty)) + 
    geom_histogram() + 
    theme_classic() + 
    labs(
      y = "Count",
      x = "Difficulty"
    ) 
}


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

plot_with_salary <- function(professors, salaries) {
  professors %>% inner_join(salaries, by=c("college" = "school_name")) %>% 
    ggplot(aes(difficulty, rating, color = starting_median_salary)) + geom_point()
}

plot_with_salary_facet_wrap <- function(professors, salaries) {
  professors %>% inner_join(salaries, by=c("college" = "school_name")) %>% 
    ggplot(aes(difficulty, rating, color = starting_median_salary)) + geom_point() + facet_wrap(~starting_median_salary)
}


