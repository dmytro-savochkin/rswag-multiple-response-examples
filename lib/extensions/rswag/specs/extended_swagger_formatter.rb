# frozen_string_literal: true

module Extensions
  module Rswag
    module Specs
      module ExtendedSwaggerFormatter
        ::RSpec::Core::Formatters.register(self, :example_group_finished, :stop) if defined? ::RSpec

        def example_group_finished(notification)
          # NOTE: rspec 2.x support
          metadata = if ::Rswag::Specs::RSPEC_VERSION > 2
                       notification.group.metadata
                     else
                       notification.metadata
                     end

          # !metadata[:document] won't work, since nil means we should generate
          # docs.
          return if metadata[:document] == false
          return unless metadata.key?(:response)

          swagger_doc = @config.get_swagger_doc(metadata[:swagger_doc])

          unless doc_version(swagger_doc).start_with?('2')
            # This is called multiple times per file!
            # metadata[:operation] is also re-used between examples within file
            # therefore be careful NOT to modify its content here.
            upgrade_request_type!(metadata)
            upgrade_servers!(swagger_doc)
            upgrade_oauth!(swagger_doc)
            upgrade_response_produces!(swagger_doc, metadata)
          end

          new_swagger_block = metadata_to_swagger(metadata)
          transform_example_to_plural(swagger_doc, new_swagger_block)
          swagger_doc.deep_merge!(new_swagger_block)
        end

        # introduced from https://github.com/rswag/rswag/issues/325
        def upgrade_content!(mime_list, target_node)
          target_node[:content] ||= {}
          schema = target_node[:schema]
          return if mime_list.empty? || schema.nil?

          mime_list.each do |mime_type|
            (target_node[:content][mime_type] ||= {}).merge!(schema: schema)
          end
        end

        # mostly introduced from https://github.com/rswag/rswag/pull/304
        def stop(_notification = nil)
          @config.swagger_docs.each do |url_path, doc|
            unless doc_version(doc).start_with?('2')
              doc[:paths]&.each_pair do |_k, v|
                v.each_pair do |_verb, value|
                  is_hash = value.is_a?(Hash)
                  if is_hash && value.dig(:parameters)
                    schema_param = value.dig(:parameters)&.find do |p|
                      (p[:in] == :body || p[:in] == :formData) && p[:schema]
                    end
                    mime_list = value.dig(:consumes)
                    if value && schema_param && mime_list
                      value[:requestBody] = { content: {} } unless value.dig(:requestBody, :content)
                      mime_list.each do |mime|
                        value[:requestBody][:content][mime] = { schema: schema_param[:schema] }
                        # Fix examples with the following line.
                        if schema_param[:examples]
                          value[:requestBody][:content][mime].merge!(
                            examples: schema_param[:examples]
                          )
                        end
                      end
                    end

                    value[:parameters].reject! { |p| p[:in] == :body || p[:in] == :formData }
                  end
                  remove_invalid_operation_keys!(value)

                  # block below added to build description based on examples' descriptions
                  value[:responses].each do |_response, response_data|
                    response_data[:content].each do |_mime, mime_data|
                      next if mime_data[:examples].blank?

                      response_data[:description] = mime_data[:examples].keys.join(' / ')
                    end
                  end
                end
              end
            end

            file_path = File.join(@config.swagger_root, url_path)
            dirname = File.dirname(file_path)
            FileUtils.mkdir_p dirname unless File.exist?(dirname)

            File.open(file_path, 'w') do |file|
              file.write(pretty_generate(doc))
            end

            @output.puts "Swagger doc generated at #{file_path}"
          end
        end

        private

        # This transforms single :example blocks into plural :examples blocks allowing us to have
        # several examples for the same response code in the specs.
        def transform_example_to_plural(swagger_doc, new_swagger_data)
          return if new_swagger_data.blank? || new_swagger_data[:paths].blank?

          new_swagger_data[:paths].each do |path, path_data|
            path_data.each do |action, action_data|
              action_data[:responses].each do |response, response_data|
                response_data[:content].each do |mime, mime_data|
                  next unless mime_data.key?(:example)

                  existing_mime_data =
                    swagger_doc[:paths].dig(path, action, :responses, response, :content, mime)
                  next if existing_mime_data.nil?

                  if existing_mime_data.key?(:example)
                    description =
                      swagger_doc[:paths][path][action][:responses][response][:description]
                    existing_mime_data[:examples] = {
                      description => { value: existing_mime_data[:example] }
                    }
                    existing_mime_data.delete(:example)
                  end

                  mime_data[:examples] = {
                    response_data[:description] => { value: mime_data[:example] }
                  }
                  mime_data.delete(:example)
                end
              end
            end
          end
        end
      end
    end
  end
end
