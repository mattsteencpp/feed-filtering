ruby /home/ubuntu/feeds_control/generate_feeds.rb /home/ubuntu/feeds_control/atlantic_config.xml > /tmp/atlantic_feed.txt
ruby /home/ubuntu/feeds_control/generate_feeds.rb /home/ubuntu/feeds_control/arseblog_config.xml > /tmp/arseblog_feed.txt
ruby /home/ubuntu/feeds_control/generate_feeds.rb /home/ubuntu/feeds_control/on_being_config.xml > /tmp/on_being_feed.txt
ruby /home/ubuntu/feeds_control/generate_feeds.rb /home/ubuntu/feeds_control/fresh_air_config.xml > /tmp/fresh_air_feed.txt
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
cp /var/www/html/feeds/the_atlantic_monthly/trump.xml /home/ubuntu/feeds_control/trump/trump_$timestamp
