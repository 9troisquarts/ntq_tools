require 'ntq_tools/translations/yaml_tool'
require 'yaml'

module NtqTools
  module Translations
    class TranslationTool
      @@yamls_by_language = nil
    
      def self.load_files(file_pathnames)
        @@yamls_by_language = {}
        I18n.available_locales.each do |locale|
          @@yamls_by_language[locale.to_s] = {} unless @@yamls_by_language[locale.to_s]
    
          locales_file = file_pathnames.select{|path| path.include?("#{locale}.yml")}
          locales_file.each do |path|
            next if @@yamls_by_language[locale.to_s][path]
            
            @@yamls_by_language[locale.to_s][path] = YamlTool.new(path)
          end
        end
      end
    
      def self.path_for_scope(locale, scope = nil)
        filename = [scope, locale.to_s, "yml"].reject(&:blank?).join(".")
        "#{::Rails.root}/config/locales/#{filename}"
      end
    
      def self.file_exists_for_scope?(locale, scope = nil)
        File.exists?(path_for_scope(locale, scope))
      end
    
      def self.create_locale_file(locale, scope = nil)
        puts "Creating a file at #{path_for_scope(locale, scope)}"
        path = path_for_scope(locale, scope)
        File.open(path, "w+") { |file| file.write({ "#{locale.to_s}": nil }.to_yaml) }
        @@yamls_by_language[locale.to_s] = {} unless @@yamls_by_language[locale.to_s]
        @@yamls_by_language[locale.to_s][path] = YamlTool.new(path)
        true
      end

      def self.key_is_in_file(file, locale, key)
        key = [locale.to_s, key].join('.') if file.get_value(locale.to_s)
        file.get_value(key).present?
      end
    
      def self.search_key_for_locale(locale, searched_key)
        files = @@yamls_by_language[locale.to_s] || []
        files.each do |pathname, file|  
          found = key_is_in_file(file, locale, searched_key)

          return file if found
          
          k = searched_key.split(".")
          if k[0..-2].length > 0
            file = search_key_for_locale(locale, k[0..-2].join("."))
            return file if file
          end
        end
        nil
      end
    
      def self.modify(key, values)
        config_folder = "#{::Rails.root}/config/locales/*.yml"
        file_pathnames = Dir[config_folder]
        return unless file_pathnames && file_pathnames.size > 0
        
        load_files(file_pathnames) unless @@yamls_by_language
        
        available_locales = I18n.available_locales.map(&:to_s)
        
        default_scope = search_key_for_locale(I18n.default_locale, key)&.filename
        default_scope = "" unless default_scope
    
        values.each do |locale, v|
          next unless available_locales.include?(locale.to_s) || v.blank?
    
          scope = search_key_for_locale(locale, key)&.filename
          if !scope
            create_locale_file(locale, default_scope) unless file_exists_for_scope?(locale, default_scope)
            scope = default_scope
          end
          yaml = @@yamls_by_language[locale.to_s][path_for_scope(locale, scope)]
          key = [locale.to_s, key].join('.') if yaml.get_value(locale.to_s)
          yaml.set_value(key, v) if yaml
        end
        
      end
    end
  end
end