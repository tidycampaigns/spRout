#' @title get_content_data_all
#' @description  Determines how many pages of data exist, pulls it all in as a singular table and joins back profile names and types
get_content_data_all <- function(token, id, profile_list, type, start, end){
  
  #Get raw data for first page
  contents <- get_content_data(token,id,profile_list,1,type, start, end, TRUE)
  
  total_data <- contents[1]
  
  tot_pages <- contents[2]
  
  #If there are more than 1 page of data, make API calls for the rest
  if(tot_pages > 1){
    
    # Create a list for all the pages of data
    seq <- seq(from=2, to=tot_pages, by=1)
    
    # Make API Call for each page of data. Smush into one table and add back page 1
    total_data <- purrr::pmap_dfr(list(token,seq,type,start,end), get_content_data) %>% 
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