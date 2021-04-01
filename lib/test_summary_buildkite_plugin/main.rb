# frozen_string_literal: true

module TestSummaryBuildkitePlugin
  class Main
    MAX_MARKDOWN_SIZE = 100_000

    attr_reader :options

    def initialize(options)
      @options = options
    end

    def run
      processor = Processor.new(
        formatter_options: formatter,
        max_size: MAX_MARKDOWN_SIZE,
        inputs: inputs,
        fail_on_error: fail_on_error
      )

      processor.markdowns.each_with_index.reverse_each do |result, idx|
        if result[:truncated].nil? || result[:truncated].empty?
          puts('No errors found! 🎉')
        else
          upload_artifact(result[:full], result[:output_path])
          annotate(result[:truncated], idx)
        end
      end
    end

    private

    def upload_artifact(markdown, output_path)
      File.write(output_path, Utils.standalone_markdown(markdown))
      Agent.run('artifact', 'upload', output_path)
    end

    def annotate(markdown, idx)
      Agent.run('annotate', '--context', "#{context}-#{idx}", '--style', style, stdin: markdown)
    end

    def formatter
      options[:formatter] || {}
    end

    def inputs
      @inputs ||= options[:inputs].map { |opts| Input.create(opts.merge(fail_on_error: fail_on_error)) }
    end

    def context
      options[:context] || 'test-summary'
    end

    def style
      options[:style] || 'error'
    end

    def fail_on_error
      options[:fail_on_error] || false
    end
  end
end
