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

  def read_lines(start_idx, end_idx)
    lines = []
    count = 0
    File.foreach(filename, encoding: 'ascii') do |l|
      lines.push(l) if count >= start_idx && count < end_idx
      count += 1
    end
    lines
  end

  private

  attr_reader :filename
end
