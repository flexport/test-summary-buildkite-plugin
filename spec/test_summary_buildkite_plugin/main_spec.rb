# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TestSummaryBuildkitePlugin::Main do
  let(:params) { { inputs: inputs } }
  let(:main) { described_class.new(params) }

  subject(:run) { main.run }

  context 'with no failures' do
    let(:inputs) do
      [
        label: 'rspec',
        type: 'junit',
        artifact_path: 'foo'
      ]
    end

    it 'does not call annotate' do
      run
      expect(agent_annotate_commands).to be_empty
    end
  end

  context 'with failures' do
    let(:inputs) do
      [
        {
          label: 'rspec',
          type: 'junit',
          artifact_path: 'rspec*'
        }, {
          label: 'xunit',
          type: 'junit',
          artifact_path: 'xunit*'
        }
      ]
    end

    it 'calls annotate with correct args' do
      run
      expect(agent_annotate_commands).to match(
        [
          start_with(['annotate', '--context', 'test-summary-1', '--style', 'error']),
          start_with(['annotate', '--context', 'test-summary-0', '--style', 'error'])
        ]
      )
      expect(agent_artifact_commands).to include(include('artifact', 'upload', 'test-summary.html'))
    end

    context 'with custom style' do
      let(:params) { { inputs: inputs, style: 'warning' } }

      it 'calls annotate with correct args' do
        run
        expect(agent_annotate_commands).to match(
          [
            start_with(['annotate', '--context', 'test-summary-1', '--style', 'warning']),
            start_with(['annotate', '--context', 'test-summary-0', '--style', 'warning'])
          ]
        )
      end
    end

    context 'with custom context' do
      let(:params) { { inputs: inputs, context: 'ponies' } }

      it 'calls annotate with correct args' do
        run
        expect(agent_annotate_commands).to match(
          [
            start_with(['annotate', '--context', 'ponies-1', '--style', 'error']),
            start_with(['annotate', '--context', 'ponies-0', '--style', 'error'])
          ]
        )
      end
    end
  end
end
