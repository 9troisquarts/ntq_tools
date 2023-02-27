module NtqTools
  module Generators
    SKIPPED_ATTRIBUTE_NAMES = %w[created_at updated_at]
    class GraphqlScaffoldGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('../templates', __dir__)

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
            definition << if k.include?('_id') || k == 'id'
                            "field :#{k}, ID"
                          else
                            "field :#{k}, Integer"
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

        attributes = []
        class_name.constantize.columns_hash.map do |k, v|
          next if SKIPPED_ATTRIBUTE_NAMES.include?(k)

          case v.type
          when :string, :text
            attributes << "argument :#{k}, String, required: false"
          when :integer
            attributes << if k.include?('_id') || k == 'id'
                            "argument :#{k}, ID, required: false"
                          else
                            "argument :#{k}, Integer, required: false"
                          end
          when :boolean
            attributes << "argument :#{k}, Boolean, required: false"
          when :decimal
            attributes << "argument :#{k}, Float, required: false"
          when :date, :datetime
            attributes << "argument :#{k}, Types::TimeType, required: false"
          else
            raise "Type non défini: #{v.type.inspect}"
          end
        end

        associations = []
        %i[belongs_to has_one].each do |association_type|
          class_name.constantize.reflect_on_all_associations(association_type).each do |asso|
            class_name = asso.options.dig(:class_name) || asso.name.to_s.singularize.camelcase
            associations << "field :#{asso.name}, Types::#{class_name}Type"
          end
        end
        [:has_many].each do |association_type|
          class_name.constantize.reflect_on_all_associations(association_type).each do |asso|
            class_name = asso.options.dig(:class_name) || asso.name.to_s.singularize.camelcase
            next if class_name == 'PaperTrail::Version'

            associations << "field :#{asso.name}, [Types::#{class_name}Type]"
          end
        end

        # Type file
create_file "app/graphql/types/#{plural_name}/#{singular_name}_type.rb", <<~FILE
module Types
  module #{plural_name.camelcase}
    class #{singular_name.camelcase}Type < BaseObject
      include Resolvers::TimestampsFields

      #{definition.join('
      ')}

      ## Associations

      #{associations.join('
      ')}
    end
  end
end
FILE

# Attributes file
create_file "app/graphql/input_object/#{singular_name}_attributes.rb", <<~FILE
module InputObject
  class #{singular_name.camelcase}Attributes < AttributesInputObject
    #{attributes.join('
    ')}
  end
end
FILE

# Attributes file
create_file "app/graphql/input_object/search_#{plural_name}_attributes.rb", <<~FILE
module InputObject
  class Search#{plural_name.camelcase}Attributes < AttributesInputObject

  end
end
FILE

        # Create mutation
        create_file "app/graphql/mutations/#{plural_name}/create_#{singular_name}.rb", <<~FILE
          module Mutations
            class #{plural_name.camelcase}::Create#{singular_name.camelcase} < BaseMutation
              field :flash_messages, [Types::JsonType], null: false
              field :#{singular_name}, Types::#{singular_name.camelcase}Type, null: false

              argument :attributes, InputObject::#{singular_name.camelcase}Attributes, required: true

              def authorized?(attributes:)
                context[:current_user].can?(:create, #{singular_name.camelcase})
              end

              def resolve(attributes:)
                #{singular_name} = ::#{singular_name.camelcase}.new
                #{singular_name}.attributes = attributes
                #{singular_name}.save!
                {
                  #{singular_name}: #{singular_name},
                  flash_messages: [
                    {
                      type: 'success',
                      message: I18n.t(:'flashes.#{plural_name}.create.success')
                    }
                  ]
                }
              end
            end
          end
        FILE

        # Update mutation
        create_file "app/graphql/mutations/#{plural_name}/update_#{singular_name}.rb", <<~FILE
          module Mutations
            class #{plural_name.camelcase}::Update#{singular_name.camelcase} < BaseMutation
              field :flash_messages, [Types::JsonType], null: false
              field :#{singular_name}, Types::#{singular_name.camelcase}Type, null: false

              argument :id, ID, required: true
              argument :attributes, InputObject::#{singular_name.camelcase}Attributes, required: true

              def authorized?(attributes:, id:)
                #{singular_name} = ::#{singular_name.camelcase}.find id
                context[:current_user].can?(:update, #{singular_name})
              end

              def resolve(attributes:, id:)
                #{singular_name} = ::#{singular_name.camelcase}.find id
                #{singular_name}.attributes = attributes
                #{singular_name}.save!
                {
                  #{singular_name}: #{singular_name},
                  flash_messages: [
                    {
                      type: 'success',
                      message: I18n.t(:'flashes.#{plural_name}.update.success')
                    }
                  ]
                }
              end
            end
          end
        FILE

        # Delete mutation
        create_file "app/graphql/mutations/#{plural_name}/delete_#{singular_name}.rb", <<~FILE
          module Mutations
            class #{plural_name.camelcase}::Delete#{singular_name.camelcase} < BaseMutation
              field :flash_messages, [Types::JsonType], null: false

              argument :id, ID, required: true

              def authorized?(id:)
                #{singular_name} = ::#{singular_name.camelcase}.find id
                context[:current_user].can?(:destroy, #{singular_name})
              end

              def resolve(id:)
                #{singular_name} = ::#{singular_name.camelcase}.find id
                #{singular_name}.destroy!
                {
                  flash_messages: [
                    {
                      type: 'success',
                      message: I18n.t(:'flashes.#{plural_name}.delete.success')
                    }
                  ]
                }
              end
            end
          end
        FILE

        puts 'Do you want to create the payload file ? (y/n)'
        input = $stdin.gets.strip
        if input == 'y'
          create_file "app/graphql/types/#{plural_name}/#{singular_name}_list_payload.rb", <<~FILE
            module Types
              module #{plural_name.camelcase}
                class #{singular_name.camelcase}ListPayload < BaseObject
                  field :#{plural_name}, [#{singular_name.camelcase}::#{singular_name.camelcase}Type], null: true
                  field :pagination, PaginationType, null: true
                end
              end
            end
          FILE
        end
      end
    end
  end
end
