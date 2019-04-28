# frozen_string_literal: true
require 'sinatra/base'
require 'redis'

require_relative 'my_model'

module App
  class Controller < Sinatra::Base
    configure do
      set :file_path, ENV['FILE_PATH']
      set :file_length, ENV['FILE_LINE_COUNT'].to_i
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
      settings.file_line_count.to_s
    end

    get '/lines/:index' do
      if params[:index].to_i > file_length
        [
          413,
          "You requested a file index past the file length of #{file_length}"
        ]
      else
        'Valid'
      end
    end

    private

    # @return [Fixnum] number of lines in the file
    def file_length
      settings.file_length
    end

    def redis
      @redis ||= Redis.new(host: '127.0.0.1', port: 6379, db: 1)
    end
  end
end
