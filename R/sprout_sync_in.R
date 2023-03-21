#This script shows how I used the helper functions I created. This is probably good candidate/jumping point for functions we put in the impact package. Or we can bundle up more of this code in the form of more helper functions.

library(httr)
library(jsonlite)
library(dplyr)
library(tidyr, include.only=c('unnest_wider','unnest_longer'))
library(lubridate, include.only='today')
library(civis)

# read in helper functions
source("vendors/sprout/sprout_helper_functions.R")

# Date range for request JSON
today <- today()
days <- Sys.getenv('start') %>% as.numeric()
start_day <- today() -days

# Retrieve schema name
schema_name <- Sys.getenv('schema')

# Create table names for output
posts_table <- glue::glue("{schema_name}.sprout_posts_data")
profiles_table <- glue::glue("{schema_name}.sprout_profiles_data")

# Get API token
sprout_token <- paste0("Bearer ",Sys.getenv('api_password'))

# retrieve customerID for future calls
customer_id <- get_customer_id(sprout_token)

# Ok, now lets see what we're working with
customer_url <- glue::glue("https://api.sproutsocial.com/v1/{customer_id}/metadata/customer")

customer_raw <- GET(customer_url, add_headers("Authorization" = sprout_token))

# Turning JSON into readable data
customer_data <- content(customer_raw) %>%
  tibble(newdata=`.`) %>%
  unnest_longer(newdata) %>%
  unnest_wider(newdata)

#Pull the list of profile_ids for all accounts to use in the body of future requests
customer_list <- customer_data %>%
  pull(customer_profile_id) %>%
  glue::glue_collapse(sep=',')


#Putting each set of data in a try blocks so that the failure of one step doesn't prevent the others from running

# Posts data:
tryCatch({
  # Pulling data together
  posts_data <- build_table(sprout_token,customer_id,customer_list,'posts',start_day,today)
  
  print("New posts data pulled succesfully")
}, error = function(error_condition) {
  # Print to log
  print("Error with new posts data, likely isnt any")
})

tryCatch({
  # adding calculated metrics as defined by the API documentation
  posts_data2 <- posts_data %>%
    unnest_wider(hashtags, names_sep = '_') %>% 
    rowwise() %>% 
    mutate(
      engagements = case_when(network_type == 'twitter' ~sum(lifetimelikes,lifetimecomments_count,lifetimeshares_count,lifetimepost_link_clicks,lifetimepost_content_clicks_other,lifetimeengagements_other, na.rm = TRUE)
                              ,network_type == 'facebook' ~sum(lifetimereactions, lifetimecomments_count, lifetimeshares_count, lifetimepost_link_clicks, lifetimepost_content_clicks_other, na.rm = TRUE)
                              ,network_type == 'fb_instagram_account' ~sum(lifetimelikes, lifetimecomments_count, lifetimecomments_count, lifetimesaves, na.rm = TRUE))
      ,follower_engagement_rate = engagements/lifetime_snapshotfollowers_count
      ,impression_engagement_rate = engagements/lifetimeimpressions
      ,click_through_rate = lifetimepost_link_clicks/lifetimeimpressions
    )
  
  print("Calculated posts metrics generated successfully")
  
  posts_data_final <- posts_data2 %>% 
    missing_columns('posts',schema_name)
  
  print("Missing columns added")
  
  # Write data to redshift
  write_civis(posts_data_final,posts_table,database='TMC', if_exists=Sys.getenv('exists'))

  print("Posts Data Appended")
  
}, error = function(error_condition) {
  
  tryCatch({
    print("Error with calculated posts metrics")
    
    posts_data_final <- posts_data %>%
      missing_columns('posts',schema_name)

    print("Missing columns added")
    # Write data to redshift
    write_civis(posts_data_final,posts_table,database='TMC', if_exists=Sys.getenv('exists'))

    print("Appending posts API metrics only")
    }, error = function(error_condition) {
    # Print to log
    print("Error adding any new posts data")
  })

})

# Profiles data:
tryCatch({

  # Pulling data together
  profiles_data <- build_table(sprout_token,customer_id,customer_list,'profiles',start_day,today)
  
  print("New profiles data pulled succesfully")
  
}, error = function(error_condition) {
  # Print to log
  print("Error with new profiles data, likely isnt any")
})

tryCatch({
  # adding calculated metrics as defined by the API documentation
  profiles_data2 <- profiles_data %>% 
    rename(reporting_periodbyday=`reporting_periodby(day)`) %>% 
    rowwise() %>% 
    mutate(
      engagements = case_when(network_type == 'twitter' ~sum(likes,comments_count,shares_count,post_link_clicks,post_content_clicks_other,engagements_other, na.rm = TRUE)
                              ,network_type == 'facebook' ~sum(reactions,comments_count,shares_count,post_link_clicks,post_content_clicks_other, na.rm = TRUE)
                              ,network_type == 'fb_instagram_account' ~sum(likes,comments_count,saves,story_replies, na.rm = TRUE))
      ,follower_engagement_rate = engagements/lifetime_snapshotfollowers_count
      ,impression_engagement_rate = engagements/impressions
      ,click_through_rate = case_when(network_type %in% c('twitter','facebook') ~post_link_clicks/impressions)
      ,profile_actions = case_when(network_type == 'fb_instagram_account' ~sum(email_contacts,get_directions_clicks,phone_call_clicks,text_message_clicks,website_clicks, na.rm = TRUE))) 
  
  print("Calculated profiles metrics generated successfully")

  # Adding in blank missing columns for append
  profiles_data_final <- profiles_data2 %>% 
    missing_columns('profiles',schema_name)
  
  print("Missing columns added")
  
  # Write data to redshift
  write_civis(profiles_data_final,profiles_table,database='TMC', if_exists=Sys.getenv('exists'))

  print("Profiles Data Appended")
  
}, error = function(error_condition) {
  
  tryCatch({
    print("Error with calculated profiles metrics")
    
    profiles_data_final <- profiles_data %>%
      missing_columns('profiles',schema_name)

    print("Missing columns added")
    # Write data to redshift
    write_civis(profiles_data_final,profiles_table,database='TMC', if_exists=Sys.getenv('exists'))

    print("Appending profiles API metrics only")

  }, error = function(error_condition) {
    # Print to log
    print("Error adding any new profiles data")
  })

})


####### Potential v2 code IGNORE #######
# Return List of fields to avoid hardcoding - NOT WORKING UGGGHHH
# posts_fields_url <- glue::glue("https://api.sproutsocial.com/v1/{customer_id}/analytics/posts?fields=*")
# fields_raw <- GET(posts_fields_url, add_headers("Authorization" = cca_sprout_token)) 