# frozen_string_literal: true
require 'sinatra/base'
require 'redis'

require_relative 'my_model'

module App
  class Controller < Sinatra::Base
    get '/keys' do
      redis.keys.map { |k| { key: k, value: redis.get(k) } }.to_json
    end

    post '/keys/:key' do
      key = params['key']
      redis.set(key, "value-for-#{key}")
    end

    private

    def redis
      @redis ||= Redis.new(host: '127.0.0.1', port: 6379, db: 1)
    end
  end
end
