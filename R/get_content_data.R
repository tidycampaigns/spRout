#' @title get_content_data
#' @description Return contents of API call for one page worth of data
#' 
#' @param token formatted API token
#' @param customer_id customer_id returned from get_customer_id function, used in json payload
#' @param customer_list list of profile_ids for all accounts, used in json payload
#' @param page page number for data to pull, used in json payload
#' @param type whether you're pulling profiles or posts data
#' @param start start date, used in json payload
#' @param end end date, used in json payload
#' @param total_pages option to also return the total number of pages of data for looping purposes. Defaults to FALSE
#' 
#' @export
#' @import httr
#' @import dplyr
#' @importFrom glue "glue"
get_content_data <- function(token, customer_id, customer_list, page, type, start, end, total_pages = FALSE){
  
  # Printing status
  print(glue("Getting raw page {page} data"))
  
  body <- source(glue("vendors/sprout/{type}_metrics_json.r"), local = TRUE)[1] %>% as.character()
  
  # Make API call
  rest_data <- POST(url = glue::glue("https://api.sproutsocial.com/v1/{customer_id}/analytics/{type}")
       ,body = body
       ,content_type_json()
       ,accept_json()
       ,add_headers("Authorization" = token, "Content-Type" = "application/json"))
  
  rest_data2 <- content(rest_data)[1]$data %>% 
    tibble(newdata=`.`) %>% 
    unnest_wider(newdata) %>% 
    unnest_wider(metrics)
  
  if(type == 'profiles'){
    rest_data2 <- rest_data2 %>% 
      unnest_wider(dimensions)
  }
  
  if(total_pages == TRUE){
    
    num_pages <- content(rest_data)$paging[[2]] %>% 
      as.numeric()
    
    return(list(data_content = rest_data2, tot_pages = num_pages))
    
  }else{
    
    return(rest_data2)
    
  }
  
}