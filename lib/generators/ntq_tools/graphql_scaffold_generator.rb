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

        p definition

        # Type file
        create_file "app/graphql/types/#{plural_name}/#{singular_name}_type.rb", <<~FILE
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

        # Create mutation
        create_file "app/graphql/mutations/#{plural_name}/create_#{singular_name}.rb", <<~FILE
          module Mutations
            class #{plural_name.capitalize}::Create#{singular_name.capitalize} < BaseMutation
              field :flash_messages, [Types::JsonType], null: false

              argument :attributes, InputObject::#{plural_name.capitalize}Attributes, required: true

              def authorized?(attributes:)
                context[:current_user].can?(:manage, #{singular_name})
              end

              def resolve(attributes:)
                object = #{singular_name.capitalize}.new
                object.attributes = attributes
                object.save!
                {
                  flash_messages: [
                    #{singular_name} = object,
                    {
                      type: 'success',
                      message: I18n.t(:'flashes.#{plural_name}.create_#{singular_name}.success')
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
            class #{plural_name.capitalize}::Delete#{singular_name.capitalize} < BaseMutation
              field :flash_messages, [Types::JsonType], null: false

              argument :id, ID, required: true

              def authorized?(id:)
                #{singular_name} = #{singular_name.capitalize}.find id
                context[:current_user].can?(:manage, #{singular_name})
              end

              def resolve(id:)
                #{singular_name} = #{singular_name.capitalize}.find id
                #{singular_name}.destroy!
                {
                  flash_messages: [
                    {
                      type: 'success',
                      message: I18n.t(:'flashes.#{plural_name}.delete_#{singular_name}.success')
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
            class #{plural_name.capitalize}::Update#{singular_name.capitalize} < BaseMutation
              field :flash_messages, [Types::JsonType], null: false

              argument :id, ID, required: true
              argument :attributes, InputObject::#{plural_name.capitalize}Attributes, required: true

              def authorized?(attributes:, id:)
                #{singular_name} = #{singular_name.capitalize}.find id
                context[:current_user].can?(:manage, #{singular_name})
              end

              def resolve(attributes:, id:)
                object = #{singular_name.capitalize}.find id
                object.attributes = attributes
                object.save!
                {
                  flash_messages: [
                    {
                      type: 'success',
                      message: I18n.t(:'flashes.#{plural_name}.update_#{singular_name}.success')
                    }
                  ]
                }
              end
            end
          end
        FILE
      end
    end
  end
end
