# this script performs basic file and directory creation tasks required to set up a new feed

require 'nokogiri'
require 'fileutils'

example_feed_name = "on_being"
user = "msteen"

if ARGV.length != 1
	puts "The required argument to this script is the feed name"
	abort
end

feed_name = ARGV[0]

puts "Reading the config file..."
config = Nokogiri::XML(File.read("/home/ubuntu/feeds_control/" + feed_name + "_config.xml"),&:noblanks)


directory = config.css('directory').text
puts "Creating the web directory from the config file: " + directory + "..."
FileUtils::mkdir_p(directory)


puts "Copying the seed files to the web directory..."
local_seed_dir = "/home/ubuntu/feeds_control/" + feed_name + "/"
filename = local_seed_dir + feed_name + ".xml"
FileUtils::cp(filename, directory)
filename = local_seed_dir + "excluded.xml"
FileUtils::cp(filename, directory)

FileUtils::chown_R("ubuntu", "ubuntu", directory)


puts "Final step: add log deletion for this feed: "
puts "    sudo crontab -e"
puts "    0 * * * * sudo find /home/ubuntu/feeds_control/" + feed_name + " -type f -mtime +1 -delete"
