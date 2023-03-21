#' @title get_customer_id
#' @description Determine a members customer_id which is needed for future API calls
#' 
#' @param token API key
#' 
#' @export
#' @import dplyr
#' @import httr
get_customer_id <- function(token){
  
  api_token <- paste0("Bearer ",token)
  
  client_url <- "https://api.sproutsocial.com/v1/metadata/client"
  client <- GET(client_url, add_headers("Authorization" = api_token)) %>% content()
  
  client %>% 
    data.frame() %>% 
    pull() %>% 
    as.numeric()
  
}