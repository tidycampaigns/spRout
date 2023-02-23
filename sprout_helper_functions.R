# Determine a members customerID which is needed for future API calls
get_customer_id <- function(token){
  
  client_url <- "https://api.sproutsocial.com/v1/metadata/client"
  client <- GET(client_url, add_headers("Authorization" = token)) %>% content()
  
  client %>% 
    data.frame() %>% 
    pull() %>% 
    as.numeric()
 
}

# Return raw API data
get_raw_data <- function(token, id, profile_list, page, type, start, end){
  
  #Printing status to logger
  print(glue::glue("Getting raw page {page} data"))

  body <- source(glue::glue("vendors/sprout/{type}_metrics_json.r"), local = TRUE)[1] %>% as.character()
 
# Make API call
  POST(url = glue::glue("https://api.sproutsocial.com/v1/{id}/analytics/{type}")
      ,body = body
      ,httr::content_type_json()
      ,httr::accept_json()
      ,add_headers("Authorization" = token, "Content-Type" = "application/json"))
  
}

# Return contents of API call, used when looping through pages
get_content_data <- function(token, seq, type, start, end){
  
  rest_data <- get_raw_data(token,customer_id,customer_list,seq,type,start,end) 
  
  rest_data2 <- content(rest_data)[1]$data %>% 
    tibble(newdata=`.`) %>% 
    unnest_wider(newdata) %>% 
    unnest_wider(metrics)
  
  if(type == 'profiles'){
    rest_data2 <- rest_data2 %>% 
      unnest_wider(dimensions)
  }

  return(rest_data2)
  
}

# Determines how many pages of data exist, pulls it all in as a singular table and joins back profile names and types
build_table <- function(token, id, profile_list, type, start, end){

  #Get raw data for first page
  page_1_raw <- get_raw_data(token,id,profile_list,1,type, start, end)
  
  #Get content for page 1
  total_data <- content(page_1_raw)$data %>% 
    tibble(newdata=`.`) %>% 
    unnest_wider(newdata) %>% 
    unnest_wider(metrics) 

  # Because heaven forbid two API endpoints send back field data in the same way *facepalm*
  if(type == 'profiles'){
    total_data <- total_data %>% 
      unnest_wider(dimensions)
  }
  
  # Pull out number of pages
  tot_pages <- content(page_1_raw)$paging[[2]] %>% 
    as.numeric()

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

# Function that checks if new data is missing columns or if new data has more columns and modifies datasets as necessary before appending new data 
missing_columns <- function(data, type, schema_name){
  
  #pull list of existing columns
  column_list_sql <- glue::glue("select ordinal_position as position,
                            column_name,
                            data_type,
                            case when character_maximum_length is not null
                            then character_maximum_length
                            else numeric_precision end as max_length,
                            is_nullable,
                            column_default as default_value
                            from information_schema.columns
                            where table_name = 'sprout_{type}_data'
                            and table_schema = '{schema_name}'
                            order by ordinal_position;")
  
  column_list <- civis::read_civis(sql(column_list_sql), database='TMC')
  
  #list of existing columns
  existing_columns <- column_list %>%  pull(column_name)
  
  #Names of columns in new dataset
  new_data_col <- colnames(data)
  
  #If new data has fewer columns. Add the columns to the new dataset so the data can be appended
  if(length(setdiff(existing_columns,new_data_col)) > 0){
    
    #Determine which columns are missing from new dataset
    in_old <- setdiff(existing_columns,new_data_col)
    
    #Create dummy table of missing variables
    old <- in_old %>%
      tibble(newcol = `.`) %>% 
      mutate(
        val = ' '
      ) %>% 
      tidyr::pivot_wider( names_from = newcol, values_from=val)

    print("Added columns to new data")
    
    #Add missing columns and rearrange
    data <- data %>% 
      bind_cols(old) 
    
  }
  
  if(length(setdiff(new_data_col,existing_columns)) > 0){ #If new data has more columns than current data, add null columns to current dataset so new data can be appended
    
    #Determine which columns are missing from current dataset
    in_new <- setdiff(new_data_col,existing_columns)
    
    #Loop through each new column and alter existing table to include column of null data
    purrr::map(in_new,
    function(var_name){
      new_col_sql <- glue::glue("alter table {schema_name}.sprout_{type}_data
                      add column {var_name} varchar
                      default NULL;")
      print(new_col_sql)
      
      # Read Civis function errors when it runs code that doesn't return data
      tryCatch({
        read_civis(sql(new_col_sql) ,database='TMC')
      }, error = function(error_condition) {
        # Do nothing
      })
    })
    
    print("added new columns to existing data")
    
  }
  
  # Re-pull list of column names with any new additions
  new_column_list_sql <- glue::glue("select ordinal_position as position,
                            column_name,
                            data_type,
                            case when character_maximum_length is not null
                            then character_maximum_length
                            else numeric_precision end as max_length,
                            is_nullable,
                            column_default as default_value
                            from information_schema.columns
                            where table_name = 'sprout_{type}_data'
                            and table_schema = '{schema_name}'
                            order by ordinal_position;")
  
  new_column_list <- civis::read_civis(sql(new_column_list_sql), database='TMC')
  
  #list of existing columns
  new_existing_columns <- new_column_list %>%  pull(column_name)
  
  data <- data %>%
    select(eval(new_existing_columns))
  
  return(data)
  
}
