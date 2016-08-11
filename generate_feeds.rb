# basic plan: filter input feed into multiple subfeeds and exclude some entries entirely
# read from config file to make it easy to update
# config file will consist of sections, and each section will have inclusion by title, author, or content

# still need to add more new feeds and filters
# excluded entries:
#    The Atlantic:
#        James Fallows beer updates (not clear how to best identify these...)
#    Lifehacker:
#        apple-related (how to best identify? tags?)
#     Krugman
#         Friday Night Music
#     Arseblog
#         Gentleman's Weekly Review
#         Podcast links
#         Live blog (or whatever it's called)

# deployment:
#     have this ruby script running on the web server every N minutes for each feed (Atlantic, Lifehacker, etc)
#     xml files to be updated will be the public-facing xml files...
#     idea - also save a timestamped version for debugging in another location
#     probably won't need Ruby on Rails after all...

require 'nokogiri'
require 'open-uri'

############################################
# functions
############################################

# if an entry with the same id already exists in the section, it has been updated, so remove the old version
def remove_entry_from_section(entry, section_entries)
	id = entry.css("id").text
	section_entries.each do |s_entry|
		s_id = s_entry.css("id").text
		if s_id == id
			s_entry.remove
			return true
		end
	end
	return false
end

# returns true if the entry matches any of the settings in the config file
def does_entry_match_section(entry, section)
	entry_author = entry.css('author name').text
	entry_title = entry.css('title').text
	entry_content = entry.css('content').text
	entry_link = entry.css('feedburner|origLink').text
	
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

max_entries = 20

# read the input config file
config = Nokogiri::XML(File.read(ARGV[0]),&:noblanks)
url = config.css('feed-url').text
selector = config.css('item-selector').text
sections = config.css('section')
directory = config.css('directory').text
feed_filename = config.css('feed-filename').text + Time.now().strftime("_%Y%m%d-%H%M%S.xml")

# read the latest from the feed url
feed = Nokogiri::XML(open(url),&:noblanks);

# write the feed to a timestamped file
File.open(feed_filename, 'w') do |file|
	file.print feed.to_xml(indent:4)
end

entries = feed.xpath(selector)
updated_timestamp = feed.at_xpath("//xmlns:updated").text

sections.each do |section|
	filename = directory + "/" + section.css('filename').text
	
	section_data = File.read(filename)
	doc = Nokogiri::XML.parse(section_data,&:noblanks)
	
	section_file_updated = doc.css("feed updated")
	section_file_updated[0].content = updated_timestamp
	
	section_nodeset = doc.at_xpath("//xmlns:feed")
	
	found = false
	puts "Looking for matches for section '" + section.css('name').text + "'"
	entries.reverse_each do |entry|
		if does_entry_match_section(entry, section)
			found = true
			entry = entries.delete(entry)
			section_entries = doc.xpath(selector)
			remove_entry_from_section(entry, section_entries)
			section_nodeset.children.first.add_previous_sibling(entry)
		end
	end
	if not found
		puts "No matches found!"
	end
	puts ""
	
	section_entries = doc.xpath(selector)

	n_to_delete = section_entries.length - max_entries - 1

	for counter in 0..n_to_delete
		section_entries = doc.xpath(selector)
		entry = section_entries.last
		puts "    Deleting old entry '" + entry.css('title').text + "'"
		entry.remove
	end
	
	# Write the document to disk
	File.open(filename, 'w') do |file|
		output = doc.to_xml(indent:4)
		# note: replace "default:" because nokogiri apparently has a bug in handling namespaces
		file.print output.gsub("default:","")
	end
end


