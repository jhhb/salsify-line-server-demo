# frozen_string_literal: true

require_relative 'file_reader'
require_relative 'file_writer'
require_relative 'partition_manager'
require_relative 'redis_manager'

# @param [String] file_path
# @param [Fixnum] file_length TODO - delete this. not needed
# @param [Fixnum] index
# @param [Fixnum] partition_size
class RequestManager
  def initialize(file_path, file_length, index, partition_size)
    @file_path   = file_path
    @file_length = file_length
    @index       = index
    @partition_manager = PartitionManager.new(index, partition_size, file_path)
  end

  def manage
    if partition_manager.partition_exists?
      FileReader
        .new(partition_manager.partition_filepath)
        .read_line(partition_manager.index_for_partition_file)
    else
      maybe_write_partition_file
      FileReader.new(file_path).read_line(index)
    end
  end

  private

  def maybe_write_partition_file
    redis_manager = RedisManager.new
    if redis_manager.lock_on_key?(partition_manager.partition_filepath)
      redis_manager.update_expiration(partition_manager.partition_filepath)
      Thread.new do
        FileWriter.new.write_file(file_path, partition_manager)
      end
    end
  end

  attr_reader :file_path
  attr_reader :file_length
  attr_reader :index
  attr_reader :partition_manager
end
