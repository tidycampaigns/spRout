#' @title sprout_auth
#' @description Function that takes in an API key and formats it for future calls and stores it as a global variable
#' 
#' @param token API key, can be passed via SYS.getenv
#' 
#' @export
sprout_auth <- function(token){
  
  api_sprout <<- paste0("Bearer ",token)

}