ruby /home/ubuntu/feeds_control/generate_feeds.rb /home/ubuntu/feeds_control/atlantic_config.xml > /tmp/feed.txt
ruby /home/ubuntu/feeds_control/generate_feeds.rb /home/ubuntu/feeds_control/arseblog_config.xml > /tmp/feed.txt
timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
cp /var/www/html/feeds/the_atlantic_monthly/trump.xml /home/ubuntu/feeds_control/trump/trump_$timestamp
