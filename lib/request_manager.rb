# frozen_string_literal: true
class RequestManager
  def initialize(file_path, file_length, index)
    @file_path   = file_path
    @file_length = file_length
    @index       = index
  end

  def manage
    'Valid'
  end

  private

    attr_reader :file_path
    attr_reader :file_length
    attr_reader :index
end
