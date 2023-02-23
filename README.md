# Sprout Social API Sync
last update: 4/29/2022

## Purpose
The purpose of this program is to use Sprout Socials API to more directly and dynamically pull in member social network data. The program currently pulls both post and profile metric data, however it can be expanded in the future to pull in a lot more. [API Documentation](https://api.sproutsocial.com/docs/)

## Known Issues
Posts metric data for the afternoon of 5/5/2021 aren't being returned when requested. 5/5/2021 (entire day) was excluded from historical data.

## Helper Functions
Below contains a brief description of each helper function with their intended purpose.

**get_customer_id:** Uses the provided API key to determine the customer_id. This ID is needed for the URL for all subsequent API calls.

**get_raw_data:** Returns raw JSON data. Uses the metrics JSON files as the body of the request. Can be used to either posts or profile metrics. Written to be as type agnostic as possible.

**get_content_data:** Calls get_raw_data() and returns data contents of the raw JSON response. Used when looping through pages of data.

**build_table:** Uses get_raw_data and get_contents_data to determine how many pages of data exist, acquire all data, and join back profile names and network types (e.g. Facebook, Twitter, Instagram). Handles peculiarities within posts and profile data.

**missing_columns:** Pulls in a list of the existing columns to determine whether new data is missing columns that the existing data has, or if new data has new columns that the existing data doesn't have.

## JSON files
In order to build the body of the API request dynamically, two files were created: posts_metrics_json.r and profiles_metrics_json.r. This allows the program to fill in social network profile id's and dates with inputs from both the user and previously run API calls.

In future versions of this program these files can be updated to include more metrics. For this instance, I worked with a member to determine what they needed.

## Calculated Metrics
The following Calculated metrics were created based on API documentation

### Posts
**engagements:**  

* **Twitter:** lifetime.likes + lifetime.comments_count + lifetime.shares_count + lifetime.post_link_clicks + lifetime.post_content_clicks_other + lifetime.engagements_other  
* **Facebook:** lifetime.reactions + lifetime.comments_count + lifetime.shares_count + lifetime.post_link_clicks + lifetime.post_content_clicks_other  
* **Instagram:** lifetime.likes + lifetime.comments_count + lifetime.comments_count  

**follower_engagement_rate:** engagements/lifetime_snapshot.followers_count  
**impression_engagement_rate:** engagements/lifetime.impressions  
**click_through_rate:** lifetime.post_link_clicks/lifetime.impressions

### Profiles
**engagements:**  

* **Twitter:** likes + comments_count + shares_count + post_link_clicks + post_content_clicks_other + engagements_other  
* **Facebook:** reactions + comments_count + shares_count + post_link_clicks + post_content_clicks_other  
* **Instagram:** likes + comments_count + saves + story_replies  

**follower_engagement_rate:** engagements/lifetime_snapshot.followers_count  
**impression_engagement_rate:** engagements/impressions  
**click_through_rate:**  

* **Twitter & Facebook:** post_link_clicks/impressions  

**profile_actions:**  

* **Instagram:** email_contacts + get_directions_clicks + phone_call_clicks + text_message_clicks + website_clicks  

## Adding new fields to sync
If you want to add more fields/metrics from the API to the sync the only files you will need to update are the ones with '_json' in the name. Make sure to pay attention to whether it is a field or a metric so you put it in the right place. The missing columns function should add the new fields/metrics to tables of existing syncs.

[This](https://docs.google.com/spreadsheets/d/1ms38UVT2Na3ts3HjOX5vFSXey8sba_CqR3xd_6S3KvM/edit#gid=0) spreadsheet has tables of current fields and what can still be added

## Troubleshooting
Basically, troubleshooting in R involves including print() statements where ever you need to, in order to understand where a process is breaking and what it's 'seeing'. Examples are: print("I am here") and print(var_name). In the error part of the tryCatch blocks you can use print(error_condition) to see what actual error being thrown is.
