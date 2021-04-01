# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class Processor
    include ErrorHandler

    attr_reader :formatter_options, :max_size, :inputs, :fail_on_error

    def initialize(formatter_options:, max_size:, inputs:, fail_on_error:)
      @formatter_options = formatter_options
      @max_size = max_size
      @inputs = inputs
      @fail_on_error = fail_on_error
      @_formatters = {}
    end

    def markdowns
      inputs.each_with_index.map do |input, idx|
        truncater = Truncater.new(
          max_size: max_size,
          max_truncate: input.failures.count
        ) do |truncate|
          input_markdown(idx, truncate)
        end

        { truncated: truncater.markdown, full: input_markdown(idx), output_path: output_path(idx) }
      rescue StandardError => e
        handle_error(e, diagnostics)
        result = HamlRender.render('truncater_exception', {})
        { truncated: result, full: result, output_path: output_path(idx) }
      end
    end

    private

    def input_markdown(idx, truncate = nil)
      formatter(idx).markdown(truncate)
    rescue StandardError => e
      handle_error(e)
    end

    def formatter(idx)
      @_formatters[idx] ||= Formatter.create(
        input: inputs[idx],
        output_path: output_path(idx),
        options: formatter_options
      )
    end

    def output_path(idx)
      "test-summary-#{idx}.html"
    end

    def diagnostics
      {
        formatter: formatter_options,
        inputs: inputs.each_with_index.map do |input, idx|
          {
            type: input.class,
            failure_count: input.failures.count,
            markdown_bytesize: input_markdown(idx)&.bytesize
          }
        end
      }
    end
  end
end
