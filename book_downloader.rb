require 'nokogiri'
require 'open-uri'

def main
  get_book
  audio_urls = get_audio_urls

  book_filename = "#{@book_author}. #{@book_title}.mp3"
  if File.exist?(book_filename)
    raise "book already exists: #{book_filename}"
  end

  audio_urls.each_with_index do |audio_url, index|
    puts "[#{index}/#{audio_urls.size}] Download in progress..."
    audio_file = downloader(audio_url)
    combiner(audio_file, book_filename)
  end

  puts "[#{audio_urls.size}/#{audio_urls.size}] Book downloaded!"
end

def get_book
  puts 'Enter book url:'
  url = gets.chomp
  raise 'wrong url' unless url.include? 'https://knigavuhe.org/book/'
  html = URI.open(url)
  @doc = Nokogiri::HTML(html)
  @book_title = @doc.at_css('.book_title_name').text.strip
  @book_author = @doc.at_xpath('//*[@itemprop="author"]/a').text.strip
end

def get_audio_urls
  scripts = @doc.css('script')
  scripts.each do |script|
    if !script['src'] && script.text.include?('.mp3')
      @book_script = script.text
    end
  end
  raise 'audio tracks were not found' unless @book_script

  audio_urls = @book_script.scan(/https:.*?\.mp3/)

  # remap array to normalize audio url strings
  audio_urls.map! do |audio_url|
    audio_url.gsub('\\', '')
  end

  audio_urls
end

def downloader(url)
  URI.open(url) do |file|
    return StringIO.new(file.read) # save in memory
  end
end

def combiner(audio_file, output_filename)
  if File.exist?(output_filename)
    # inserts audio into an already created file if it exists
    File.open(output_filename, 'ab') do |file|
      audio_file.rewind if audio_file.respond_to?(:rewind)
      file.write(audio_file.read)
    end
  else
    # inserts audio into a new file
    File.open(output_filename, 'wb') do |file|
      audio_file.rewind if audio_file.respond_to?(:rewind)
      file.write(audio_file.read)
    end
  end
end


main