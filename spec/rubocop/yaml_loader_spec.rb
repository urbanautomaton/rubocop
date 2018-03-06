# frozen_string_literal: true

RSpec.describe RuboCop::YAMLLoader do
  include FileHelper

  describe '.safe_load' do
    subject { described_class }

    let(:yaml_code) do
      <<-YAML.strip_indent
        Style/WordArray:
          WordRegex: !ruby/regexp '/\\A[\\p{Word}]+\\z/'
      YAML
    end

    let(:result) { subject.safe_load(yaml_code, 'some_config.yml') }

    context 'when SafeYAML is loaded' do
      context 'when it is fully required' do
        it 'de-serializes Regexp objects' do
          in_its_own_process_with('safe_yaml') do
            word_regexp = result['Style/WordArray']['WordRegex']

            expect(word_regexp.is_a?(::Regexp)).to be(true)
          end
        end
      end

      context 'when safe_yaml is loaded without monkey patching' do
        it 'de-serializes Regexp objects' do
          in_its_own_process_with('safe_yaml/load') do
            word_regexp = result['Style/WordArray']['WordRegex']

            expect(word_regexp.is_a?(::Regexp)).to be(true)
          end
        end

        context 'and SafeYAML.load is private' do
          # According to issue #2935, SafeYAML.load can be private in some
          # circumstances.
          it 'does not raise private method load called for SafeYAML:Module' do
            in_its_own_process_with('safe_yaml/load') do
              SafeYAML.send :private_class_method, :load
              word_regexp = result['Style/WordArray']['WordRegex']

              expect(word_regexp.is_a?(::Regexp)).to be(true)
            end
          end
        end
      end
    end

    context 'when SafeYAML is not loaded' do
      it 'de-serializes Regexp objects' do
        in_its_own_process_with('safe_yaml') do
          word_regexp = result['Style/WordArray']['WordRegex']

          expect(word_regexp.is_a?(::Regexp)).to be(true)
        end
      end

      context 'when a disallowed ruby object is found' do
        let(:yaml_code) do
          <<-YAML.strip_indent
            ---
            thing: !ruby/object:A {}
          YAML
        end

        it 'raises an error if a disallowed ruby object is found' do
          expect { result }.to raise_error Psych::DisallowedClass
        end
      end
    end
  end
end
