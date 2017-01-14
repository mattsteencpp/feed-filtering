# this script performs basic file and directory creation tasks required to set up a new feed

require 'nokogiri'
require 'open-uri'
require 'fileutils'

example_feed_name = "on_being"
user = "msteen"

def write_xml_to_file(user, filename, xml_object, replace_text, new_text)
	File.open(filename, 'w') do |file|
		output = xml_object.to_xml(indent:4)
		output.force_encoding 'utf-8'
		if replace_text.length > 0
			output = output.gsub(replace_text, new_text)
		end
		# note: replace "default:" because nokogiri apparently has a bug in handling namespaces
		file.print output.gsub("default:","")
	end
	FileUtils::chown(user, user, filename)
end

# replace underscores with spaces and capitalize the first letter of every word.
# example: on_being -> On Being
def get_feed_caption(name)
	caption = String.new(name)
	caption = caption.gsub("_", " ")
	caption = caption.split.map(&:capitalize).join(' ')
	puts "Generated caption '" + caption + "' for name '" + name + "'"
	return caption
end

if ARGV.length != 2
	puts "The required arguments to this script are the feed name and feed url"
	abort
end

feed_name = ARGV[0]
feed_url = ARGV[1]

# read the example config file. we will read from this and update it so it can become
# the basis for the new config file
puts "Reading the example config file..."
config = Nokogiri::XML(File.read("/home/msteen/projects/ruby/" + example_feed_name + "_config.xml"),&:noblanks)

# create the local directory for the example web config files
local_dir = "/home/msteen/projects/ruby/" + feed_name
puts "Creating the local directory " + local_dir + "..."
FileUtils::mkdir_p(local_dir)
FileUtils::chown_R(user, user, local_dir)

# set the feed url, download the feed, and copy it into the local directory
puts "Downloading raw feed from " + feed_url + "..."
url_object = config.css('feed-url')
###
url_object[0].content = feed_url
raw_feed = Nokogiri::XML(open(feed_url),&:noblanks);

# Write the full feed to disk
filename = local_dir + "/" + feed_name + "_full.xml"
puts "Writing the full feed to disk at " + filename + "..."
write_xml_to_file(user, filename, raw_feed, "", "")

# load the web directory name, update it, and create that directory.
# set its permissions to 777
directory_object = config.css('directory')

directory = directory_object.text
directory.gsub! example_feed_name, feed_name

puts "Updating the web directory in the config file and creating it at " + directory + "..."
directory_object[0].content = directory
FileUtils::mkdir_p(directory)
FileUtils::chmod(777, directory)

# try to remove all entries from the feed
# if successful, write the empty feed to file twice
puts "Attempting to remove entries and create seed file..."
entries = raw_feed.xpath("//item")
if entries.length > 0
	entries.each do |entry|
		entry.remove
	end
	
	new_feed_url = "http://www.mattsteenprojects.com/podcasts/" + feed_name + "/" + feed_name + ".xml"
	
	puts "Attempting to replace the original feed url with the new feed url: "
	puts "    " + feed_url
	puts "    " + new_feed_url
	
	filename = local_dir + "/" + feed_name + ".xml"
	write_xml_to_file(user, filename, raw_feed, feed_url, new_feed_url)
	filename = local_dir + "/excluded.xml"
	write_xml_to_file(user, filename, raw_feed, feed_url, new_feed_url)
	filename = directory + "/" + feed_name + ".xml"
	write_xml_to_file(user, filename, raw_feed, feed_url, new_feed_url)
	filename = directory + "/excluded.xml"
	write_xml_to_file(user, filename, raw_feed, feed_url, new_feed_url)
	puts "Successfully removed all items and created seed files!"
else
	puts "*******************************"
	puts "Unable to remove entries and create seed files!"
	puts "*******************************"
end

# load the feed-filename, update it, and create the containing directory
# set its permissions to 777
feed_filename_object = config.css('feed-filename')

feed_filename = feed_filename_object.text
feed_filename.gsub! example_feed_name, feed_name

puts "Updating the feed filename to " + feed_filename + "..."
feed_filename_object[0].content = feed_filename

feed_file_directory = feed_filename
final_slash_index = feed_file_directory.rindex('/')
feed_file_directory = feed_file_directory[0,final_slash_index]
puts "Creating the feed filename directory " + feed_file_directory + "..."
FileUtils::mkdir_p(feed_file_directory)
FileUtils::chmod(0777, feed_file_directory)


# update the main section of the feed
example_feed_caption = get_feed_caption(example_feed_name)
feed_caption = get_feed_caption(feed_name)

sections = config.css('section')
sections.each do |section|
	name_object = section.css('name')
	name = name_object.text
	if name == example_feed_caption
		puts "Updating the main section name and filename in the config file..."
		name_object[0].content = feed_caption
		filename_object = section.css('filename')
		filename_object[0].content = feed_name + ".xml"
	end
end

config_filename = "/home/msteen/projects/ruby/" + feed_name + "_config.xml"
puts "Saving the config file at " + config_filename + "..."
write_xml_to_file(user, config_filename, config, "", "")

puts "Remaining work: "
puts "    Create seed files if not successfully created above"
puts "    Delete the original raw feed from the seed file folder"
puts "    Update the exclusion criteria and critical selectors in the config file:"
puts "        gedit " + feed_name + "_config.xml"
puts "    Update test_generate.sh to include the new feed:"
puts "        ruby generate_feeds.rb " + feed_name + "_config.xml /home/msteen/projects/ruby/" + feed_name
puts "    Test the new feed"
puts "    Update generate_feeds.sh to include the new feed"
puts "        ruby /home/ubuntu/feeds_control/generate_feeds.rb /home/ubuntu/feeds_control/" + feed_name + "_config.xml > /tmp/" + feed_name + "_feed.txt"
puts "    Update copy_files.sh to include the new feed:"
puts "        scp -i /home/msteen/projects/web/AWSkey2.pem -r /home/msteen/projects/ruby/" + feed_name + " ubuntu@ec2-52-40-89-141.us-west-2.compute.amazonaws.com:/home/ubuntu/feeds_control"
puts "        scp -i /home/msteen/projects/web/AWSkey2.pem -r /home/msteen/projects/ruby/" + feed_name + "_config.xml ubuntu@ec2-52-40-89-141.us-west-2.compute.amazonaws.com:/home/ubuntu/feeds_control"
puts "    Commit all changes to git and push to github (git push origin master)"
puts "    Deploy the files to the server and run the update script there for the new feed"


















