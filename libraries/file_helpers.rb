# cookbooks/helper/libraries/file_helpers.rb

module FileHelpers
  def file_append(file, string)
    unless File.read(file).include? string
      File.open(file, 'a') { |f| f.puts string }
    end
  end

  # return true if the file has changed
  def file_replace(file, match, replace)
    file_contents = File.read(file)
    unless file_contents.include? replace
      file_contents.gsub!(match, replace)
      File.open(file, 'w') { |f| f.puts file_contents }
      true
    else
      false
    end
  end

  def file_remove(file, match)
    file_contents = File.read(file)
    if file_contents.include? match
      file_contents.gsub!(match, "")
      File.open(file, 'w') { |f| f.puts file_contents }
    end
  end

  def file_write(file, string)
    File.open(file, 'w') { |f| f.puts string }
  end
end
