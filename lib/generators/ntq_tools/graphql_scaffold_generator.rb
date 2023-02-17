module NtqTools
  module Generators
    SKIPPED_ATTRIBUTE_NAMES = %w[created_at updated_at]
    class GraphqlScaffoldGenerator < Rails::Generators::NamedBase
      source_root File.expand_path("../../templates", __FILE__)
    
      def create_type_file
        singular_name = plural_name.singularize
        return unless defined?(class_name.constantize) && class_name.constantize.respond_to?(:columns_hash)

        definition = []
        class_name.constantize.columns_hash.map do |k, v|
          next if SKIPPED_ATTRIBUTE_NAMES.include?(k)

          case v.type
          when :string, :text
            definition << "field :#{k}, String"
          when :integer
            if k.include?('_id') || k == 'id'
              definition << "field :#{k}, ID"
            else
              definition << "field :#{k}, Integer"
            end
          when :boolean
            definition << "field :#{k}, Boolean"
          when :decimal
            definition << "field :#{k}, Float"
          when :date, :datetime
            definition << "field :#{k}, Types::TimeType"
          else
            raise "Type non défini: #{v.type.inspect}"
          end
        end

        create_file "app/graphql/types/#{plural_name}/#{singular_name}_type.rb", <<-FILE
module Types
  module #{plural_name.capitalize}
    class #{singular_name.capitalize}Type < BaseObject
      include Resolvers::TimestampsFields

      #{definition.join('
      ')}
    end
  end
end
    FILE
      end

    end
  end
end
