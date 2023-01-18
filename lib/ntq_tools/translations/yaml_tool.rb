require 'yaml'
require 'ntq_tools/translations/hash_utils'

module NtqTools
  module Translations
    class YamlTool
      include HashUtils
    
      attr_accessor :filepath, :file, :content, :filename
    
      def initialize(filepath)
        @filepath = filepath
        @file = File.open(filepath)
        @content = YAML.load(@file.read)
        name = filepath.split("/").last.split(".")
        name = name.size <= 2 ? nil : name.first
        @filename = name
      end
    
      def write_content
        return false unless @content
    
        File.write(filepath, @content.to_yaml)
        true
      end
    
      def get_value(key)
        keys = (key.is_a?(Array) ? key : key.split('.')).map(&:to_s)
        @content.dig(*keys)
      end
    
      def set_value(key, value)
        keys = (key.is_a?(Array) ? key : key.split('.')).map(&:to_s)
        new_content = dig_set(@content, keys, value)
        write_content
        new_content
      end
    end
  end
end