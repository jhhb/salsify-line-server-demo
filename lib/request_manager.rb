# frozen_string_literal: true

require_relative 'file_reader'

class RequestManager
  def initialize(file_path, file_length, index)
    @file_path   = file_path
    @file_length = file_length
    @index       = index
  end

  def manage
    FileReader.new(file_path).read_line(index)
  end

  private

  attr_reader :file_path
  attr_reader :file_length
  attr_reader :index
end
