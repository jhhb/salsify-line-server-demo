# frozen_string_literal: true
class FileWriter
  def write_file(file_path, manager)
    `mkdir #{manager.partition_directory}`
    copied_lines = FileReader.new(file_path).read_lines(manager.input_start_index, manager.input_end_index)
    out = File.open(manager.partition_filepath, 'a')
    copied_lines.map { |l| out << l }
    out.close
  end
end
