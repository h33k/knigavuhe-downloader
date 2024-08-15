require 'nokogiri'
require 'open-uri'

def main
  get_book
  audio_urls = get_audio_urls

  if audio_urls.size > 1
    puts 'This book contains several chapters. Choose save mode:'
    puts "1: Save all chapters as one mp3 file"
    puts "2: Save each chapter as separate mp3 file"
    input = gets.chomp.downcase
    raise "invalid save mode: #{input}" unless %w[1 2].include?(input)
    @save_mode = input.to_i
  else
    @save_mode = 0
  end

  book_dirname = "#{@book_author}. #{@book_title}"
  book_filename = "#{@book_author}. #{@book_title}.mp3"
  check_for_existence(book_filename, book_dirname)

  Dir.mkdir(book_dirname) if @save_mode == 2

  audio_urls.each_with_index do |audio_url, index|
    puts "[#{index}/#{audio_urls.size}] Download in progress..."
    audio_file = downloader(audio_url)
    save_path = case @save_mode
                when 2 then "#{book_dirname}/#{index + 1}. #{@book_title}.mp3"
                else book_filename
                end
    @save_mode == 1 ? combiner(audio_file, book_filename) : saver(audio_file, save_path)
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

def check_for_existence(filename, dirname)
  case @save_mode
  when 0, 1
    raise "book already exists: #{filename}" if File.exist?(filename)
  when 2
    raise "book directory already exists: #{dirname}" if Dir.exist?(dirname)
  else
    raise "unknown save mode"
  end
end

def downloader(url)
  URI.open(url) do |file|
    return StringIO.new(file.read) # save in memory
  end
end

def saver(audio_file, output_filename)
  File.open(output_filename, 'wb') do |file|
    file.write(audio_file.read)
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