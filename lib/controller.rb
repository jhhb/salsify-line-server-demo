# frozen_string_literal: true
require 'sinatra/base'
require 'redis'

require_relative 'request_manager'

module App
  class Controller < Sinatra::Base
    configure do
      set :file_path, ENV['FILE_PATH']
      set :file_length, ENV['FILE_LINE_COUNT'].to_i
      set :partition_file_max_length, ENV['PARTITION_FILE_MAX_LENGTH'].to_i
    end

    get '/keys' do
      redis.keys.map { |k| { key: k, value: redis.get(k) } }.to_json
    end

    post '/keys/:key' do
      key = params['key']
      redis.set(key, "value-for-#{key}")
    end

    # Endpoint for debugging purposes
    get '/line_count' do
      file_length.to_s
    end

    get '/lines/:index' do
      if index_out_of_range?
        [
          413,
          "Requested index is outside the valid range of 0 - #{max_valid_index}"
        ]
      else
        RequestManager.new(file_path, file_length, index, partition_size).manage
      end
    end

    private

    def index_out_of_range?
      index > max_valid_index
    end

    def partition_size
      settings.partition_file_max_length
    end

    def max_valid_index
      file_length - 1
    end

    # @return [Fixnum] number of lines in the file
    def file_length
      settings.file_length
    end

    def file_path
      settings.file_path
    end

    def index
      params[:index].to_i
    end
  end
end
