#' @title get_customer_id
#' @description Determine a members customer_id which is needed for future API calls. Uses global api_token created by sprout_auth()
#' 
#' @export
#' @import dplyr
#' @import httr
get_customer_id <- function(){
  
  client_url <- "https://api.sproutsocial.com/v1/metadata/client"
  client <- GET(client_url, add_headers("Authorization" = api_sprout)) %>% content()
  
  client %>% 
    data.frame() %>% 
    pull() %>% 
    as.numeric()
  
}