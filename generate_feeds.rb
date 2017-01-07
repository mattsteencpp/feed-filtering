# basic plan: filter input feed into multiple subfeeds and exclude some entries entirely
# read from config file to make it easy to update
# config file will consist of sections, and each section will have inclusion by title, author, content, etc.

# deployment:
#     have this ruby script running on the web server every N minutes for each feed
#     xml files to be updated will be the public-facing xml files...

require 'nokogiri'
require 'open-uri'

############################################
# functions
############################################

# if an entry with the same id already exists in the section, it has been updated, so remove the old version
def remove_entry_from_section(item_id_selector, entry, section_entries)
	id = entry.css(item_id_selector).text
	section_entries.each do |s_entry|
		s_id = s_entry.css(item_id_selector).text
		if s_id == id
			s_entry.remove
			return true
		end
	end
	return false
end

# returns true if the entry matches any of the settings in the config file
def does_entry_match_section(entry, section, item_link_selector)
	entry_author = entry.css('author name').text
	entry_title = entry.css('title').text
	entry_content = entry.css('content').text
	entry_link = entry.css(item_link_selector).text
	
	highlights = section.css('highlight-contents')
	highlights.each do |highlight|
		if entry_content.include? highlight and not entry_title.include? highlight
			entry_title = "*** " + highlight + " *** " + entry_title
			title_object = entry.css('title')
			title_object[0].content = entry_title
		end
	end
	
	if section.css('include-all').text == "Yes"
		puts "    " + entry_title + ": Matched everything"
		return true
	end
	
	authors = section.css('include-author')
	authors.each do |author|
		if entry_author.include? author
			puts "    " + entry_title + ": Matched author '" + author + "'"
			return true
		end
	end
	titles = section.css('include-title')
	titles.each do |title|
		if entry_title.include? title
			puts "    " + entry_title + ": Matched title '" + title + "'"
			return true
		end
	end
	contents = section.css('include-content')
	contents.each do |content|
		if entry_content.include? content
			puts "    " + entry_title + ": Matched content '" + content + "'"
			return true
		end
	end
	links = section.css('include-link')
	links.each do |link|
		if entry_link.include? link
			puts "    " + entry_title + ": Matched link '" + link + "'"
			return true
		end
	end
	return false
end

############################################

# read the input config file
config = Nokogiri::XML(File.read(ARGV[0]),&:noblanks)
url = config.css('feed-url').text
max_entries = config.css('max-entries').text.to_i
item_selector = config.css('item-selector').text
item_link_selector = config.css('item-link-selector').text
item_id_selector = config.css('item-id-selector').text
feed_selector = config.css('feed-selector').text
updated_selector = config.css('updated-selector').text
stored_update_selector = config.css('stored-update-selector').text
sections = config.css('section')
feed_filename = config.css('feed-filename').text + Time.now().strftime("_%Y%m%d-%H%M%S.xml")
if ARGV.length > 2
	directory = ARGV[1]
else
	directory = config.css('directory').text
end

# read the latest from the feed url
feed = Nokogiri::XML(open(url),&:noblanks);

# write the feed to a timestamped file
File.open(feed_filename, 'w') do |file|
	file.print feed.to_xml(indent:4)
end

entries = feed.xpath(item_selector)
updated_timestamp = feed.at_xpath(updated_selector).text

sections.each do |section|
	filename = directory + "/" + section.css('filename').text
	
	section_data = File.read(filename)
	doc = Nokogiri::XML.parse(section_data,&:noblanks)
	
	section_file_updated = doc.css(stored_update_selector)
	section_file_updated[0].content = updated_timestamp
	
	section_nodeset = doc.at_xpath(feed_selector)
	
	found = false
	puts "Looking for matches for section '" + section.css('name').text + "'"
	entries.reverse_each do |entry|
		if does_entry_match_section(entry, section, item_link_selector)
			found = true
			entry = entries.delete(entry)
			section_entries = doc.xpath(item_selector)
			remove_entry_from_section(item_id_selector, entry, section_entries)
			section_nodeset.children.first.add_previous_sibling(entry)
		end
	end
	if not found
		puts "No matches found!"
	end
	puts ""
	
	section_entries = doc.xpath(item_selector)

	if max_entries > 0
		n_to_delete = section_entries.length - max_entries - 1
		
		for counter in 0..n_to_delete
			section_entries = doc.xpath(item_selector)
			entry = section_entries.last
			puts "    Deleting old entry '" + entry.css('title').text + "'"
			entry.remove
		end
	end
	
	# Write the document to disk
	File.open(filename, 'w') do |file|
		output = doc.to_xml(indent:4)
		output.force_encoding 'utf-8'
		# note: replace "default:" because nokogiri apparently has a bug in handling namespaces
		file.print output.gsub("default:","")
	end
end


