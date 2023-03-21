paste0("{
  \"fields\":[
    \"customer_profile_id\"
    ,\"guid\"
    ,\"content_category\"
    ,\"post_type\"
    ,\"post_category\"
    ,\"title\"
    ,\"hashtags\"
    ,\"created_time\"
  ],
  \"filters\":[
    \"customer_profile_id.eq(",customer_list,")\"
    ,\"created_time.in(",start,"...",end,")\"
  ],
  \"metrics\":[
    \"lifetime.impressions\"
    ,\"lifetime.post_media_views\"
    ,\"lifetime.video_views\"
    ,\"lifetime.reactions\"
    ,\"lifetime.likes\"
    ,\"lifetime.comments_count\"
    ,\"lifetime.shares_count\"
    ,\"lifetime.post_content_clicks\"
    ,\"lifetime.post_link_clicks\"
    ,\"lifetime.post_content_clicks_other\"
    ,\"lifetime.post_media_clicks\"
    ,\"lifetime.post_hashtag_clicks\"
    ,\"lifetime.post_detail_expand_clicks\"
    ,\"lifetime.post_profile_clicks\"
    ,\"lifetime.engagements_other\"
    ,\"lifetime.post_followers_gained\"
    ,\"lifetime.post_followers_lost\"
    ,\"lifetime.post_app_engagements\"
    ,\"lifetime.post_app_installs\"
    ,\"lifetime.post_app_opens\"
    ,\"lifetime_snapshot.followers_count\"
    ,\"lifetime.impressions_unique\"
    ,\"lifetime.video_views_unique\"
    ,\"lifetime.video_view_time_per_view\"
    ,\"lifetime.saves\"
  ],
  \"timezone\":\"America/Chicago\"
  ,\"page\":",page,"
}") 