#' @title get_customer_list
#' @description Pull the list of profile_ids for all accounts to use in the body of future requests. Uses global api_token created by sprout_auth()
#' 
#' @param customer_id customer_id returned from get_customer_id function
#' 
#' @return a list of the profile ids
#' 
#' @export
#' @import httr
#' @import dplyr
#' @importFrom glue "glue" "glue_collapse"
#' @importFrom tidyr "unnest_longer" "unnest_wider"
get_customer_list <- function(customer_id){
  
  customer_url <- glue("https://api.sproutsocial.com/v1/{customer_id}/metadata/customer")
  
  customer_raw <- GET(customer_url, add_headers("Authorization" = api_sprout))
  
  # Turning JSON into readable data
  customer_data <- content(customer_raw) %>%
    tibble(newdata=`.`) %>%
    unnest_longer(newdata) %>%
    unnest_wider(newdata)
  
  #Pull the list of profile_ids for all accounts to use in the body of future requests
  customer_list <- customer_data %>%
    pull(customer_profile_id) %>%
    glue_collapse(sep=',')
  
  return(customer_list)
}