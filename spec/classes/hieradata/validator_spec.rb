require 'spec_helper'
require 'lib/hieradata/validator'

include RSpecPuppetUtils

module HieraData
  class TestValidator < Validator
    def initialize
      @load_errors = []
    end
    def load
      @data = {
          :file1 => {
              'key' => 'value',
              :other => 'other value',
              'missmatch' => 'string',
              'cat' => 'black',
          },
          :file2 => {
              'hello' => 'world',
              'missmatch' => ['array'],
              'hat' => 'fedora',
          },
          :file3 => {
              'squid' => 'giant',
          }
      }
    end
    def load_empty
      @data = {}
    end
    def set_load_errors(errors)
      @load_errors = errors
    end
  end
end

describe HieraData::Validator do

  validator = HieraData::TestValidator.new
  validator.load

  it 'should have public data variable' do
    expect(validator.data).to have_key :file1
  end

  it 'should use block to validate key' do
    expect {
      validator.validate('key') { |v| expect(v).to eq 'value' }
    }.to_not raise_error

    expect {
      validator.validate('key') { |v| expect(v).to eq 'oooops' }
    }.to raise_error HieraData::ValidationError
  end

  it 'should accept symbol as key' do
    expect {
      validator.validate(:other) { |v| v == 'other value' }
    }.to_not raise_error
  end

  it 'should validate key in all files' do
    expect {
      validator.validate('missmatch') { |v| expect(v).to be_a String }
    }.to raise_error HieraData::ValidationError
  end

  it 'should return key and file in error messages' do
    expect {
      validator.validate('missmatch') { |v| expect(v).to be_a String }
    }.to raise_error HieraData::ValidationError, /missmatch is invalid in file2/
  end

  context 'when matching with regex' do

    it 'should raise error if no match is found' do
      expect {
        validator.validate(/nonex/) { }
      }.to raise_error HieraData::ValidationError, /No match for \/nonex\/ was not found/
    end

    it 'should not raise error if match is found' do
      expect {
        validator.validate(/at$/) { }
      }.to_not raise_error
    end

    it 'should validate block against all matches' do
      parser = mock()
      parser.expects(:parse).with('black').once
      parser.expects(:parse).with('fedora').once
      validator.validate(/at$/) { |v| parser.parse v }
    end

    it 'should match symbols' do
      expect {
        validator.validate(/other/) { |v| expect(v).to eq 'other value' }
      }.to_not raise_error
    end

  end

  context 'with required files' do

    it 'should raise error if required files in not an Array' do
      expect {
        validator.validate('cat', nil) { }
      }.to raise_error ArgumentError, 'required files should be an Array'
    end

    it 'should raise error when key is not found in required file' do
      expect {
        validator.validate('cat', [:file2]) { }
      }.to raise_error HieraData::ValidationError
    end

    it 'should report which files are missing the key' do
      expect {
        validator.validate('cat', [:file2, :file3]) { }
      }.to raise_error HieraData::ValidationError, 'No match for "cat" was not found in: file2, file3'
    end

    it 'should report broader error if key is not in any files' do
      expect {
        validator.validate('dog', [:file1]) { }
      }.to raise_error HieraData::ValidationError, 'No match for "dog" was not found in any files'
    end

  end

  it 'should raise error if key is not a valid type' do
    expect {
      validator.validate(['key']) { }
    }.to raise_error ArgumentError, 'Search key must be a String, Symbol or a Regexp'
  end

  it 'should raise error if there were load errors' do
    load_error_validator = HieraData::TestValidator.new
    load_error_validator.load_empty
    load_error_validator.set_load_errors ['file1 is empty', 'file2 has syntax errors']
    expect {
      load_error_validator.validate('') { }
    }.to raise_error HieraData::ValidationError, /file1 is empty\nfile2 has syntax errors/
  end

  it 'should raise error if data is nil' do
    nil_validator = HieraData::TestValidator.new
    expect {
      nil_validator.validate('meh') { }
    }.to raise_error StandardError, /No data available/
  end

  it 'should raise error if data is empty' do
    empty_validator = HieraData::TestValidator.new
    empty_validator.load_empty
    expect {
      empty_validator.validate('meh') { }
    }.to raise_error StandardError, /No data available/
  end

end

describe HieraData::ValidationError do

  it 'should inherit from StandardError' do
    expect(HieraData::ValidationError.ancestors).to include StandardError
  end

end
