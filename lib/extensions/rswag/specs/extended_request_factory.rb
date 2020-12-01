# frozen_string_literal: true

# introduced from https://github.com/rswag/rswag/pull/319
module Extensions
  module Rswag
    module Specs
      module ExtendedRequestFactory
        def add_path(request, metadata, swagger_doc, parameters, example)
          template = (swagger_doc[:basePath] || '') + metadata[:path_item][:template]
          request[:path] = template.tap do |path_template|
            parameters.select { |p| p[:in] == :path }.each do |p|
              path_template.gsub!("{#{p[:name]}}", example.send(p[:name]).to_s)
            end

            parameters.select { |p| p[:in] == :query }.each_with_index do |p, i|
              path_template.concat(i.zero? ? '?' : '&')
              path_template.concat(
                build_query_string_part(p, example.send(p[:name]), swagger_doc)
              )
            end
          end
        end

        def param_is_array?(param)
          param[:type]&.to_sym == :array || param.dig(:schema, :type)&.to_sym == :array
        end

        def build_query_string_part(param, value, swagger_doc)
          name = param[:name]
          if doc_version(swagger_doc).start_with?('2')
            return "#{name}=#{value}" unless param[:type].to_sym == :array
          else # Openapi3
            return "#{name}=#{value}" unless param_is_array?(param)
          end
          case param[:collectionFormat]
          when :ssv
            "#{name}=#{value.join(' ')}"
          when :tsv
            "#{name}=#{value.join('\t')}"
          when :pipes
            "#{name}=#{value.join('|')}"
          when :multi
            value.map { |v| "#{name}=#{v}" }.join('&')
          else
            "#{name}=#{value.join(',')}" # csv is default
          end
        end
      end
    end
  end
end
