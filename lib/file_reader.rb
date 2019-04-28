# frozen_string_literal: true
class FileReader
  def initialize(filename)
    @filename = filename
  end

  def read_line(n)
    count = 0
    File.foreach(filename, encoding: 'ascii') do |l|
      return l if count == n
      count += 1
    end
  end

  private

  attr_reader :filename
end
