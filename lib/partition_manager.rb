# frozen_string_literal: true
# The purpose of the PartitionManager is to provide an interface for
# chunking the input file into smaller subfiles. It does this by determining
# partitions and partition sizes and offsets for the given set of parameters
# frozen_string_literal: true
class PartitionManager
  attr_reader :partition_size

  # @param
  def initialize(requested_index, partition_size, input_filename)
    @requested_index = requested_index
    @partition_size = partition_size
    @input_filename = input_filename
  end

  def partition_filename
    partition_filepath.split('/')[-1]
  end

  def partition_directory
    partition_filepath.split('/')[0]
  end

  # @return [String]
  # return a string that is unique per partition_size setting and file_name.
  # This makes it so that we can alter either of the two and correctly
  # maintain references to any chunked files
  def partition_filepath
    "partition_file_max_length_#{partition_size}_#{input_filename}/#{partition_num_for_index}.txt"
  end

  def partition_num_for_index
    requested_index / partition_size
  end

  def index_for_partition_file
    requested_index % partition_size
  end

  def input_start_index
    partition_num_for_index * partition_size
  end

  def input_end_index
    input_start_index + partition_size
  end

  def partition_exists?
    File.exist?(partition_filepath)
  end

  private

  attr_reader :requested_index
  attr_reader :input_filename
end
