#' @title get_content_data_all
#' @description  Determines how many pages of data exist, pulls it all in as a singular table and joins back profile names and types. Uses global api_token created by sprout_auth()
#' 
#' @param customer_id customer_id returned from get_customer_id function, used in json payload
#' @param customer_list list of profile_ids for all accounts, used in json payload
#' @param type whether you're pulling profiles or posts data
#' @param start start date, used in json payload
#' @param end end date, used in json payload
#' 
#' @export
#' @import httr
#' @import dplyr
#' @importFrom glue "glue"
get_content_data_all <- function(customer_id, customer_list, type, start, end){
  
  #Get raw data for first page
  contents <- get_content_data(api_sprout,id,customer_list,1,type, start, end, TRUE)
  
  total_data <- contents[1]
  
  tot_pages <- contents[2]
  
  #If there are more than 1 page of data, make API calls for the rest
  if(tot_pages > 1){
    
    # Create a list for all the pages of data
    seq <- seq(from=2, to=tot_pages, by=1)
    
    # Make API Call for each page of data. Smush into one table and add back page 1
    total_data <- purrr::pmap_dfr(list(api_sprout,seq,type,start,end), get_content_data) %>% 
      bind_rows(total_data)
    
  }
  
  # BECAUSE WHY HAVE THE SAME VARIABLE BE THE SAME TYPE????  
  if(type == 'posts'){
    total_data <- total_data %>% 
      mutate(
        customer_profile_id = as.numeric(customer_profile_id)
      )
  }
  
  #Adding back network type and profile name
  total_data <- total_data %>% 
    left_join(customer_data %>% select(customer_profile_id, profile_name=name, network_type)
              ,by='customer_profile_id') 
  
  # removing periods from column names
  colnames(total_data) <- gsub("\\.", "", colnames(total_data))
  
  return(total_data)
  
}