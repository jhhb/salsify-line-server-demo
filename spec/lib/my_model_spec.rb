# frozen_string_literal: true
require_relative '../spec_helper.rb'

describe MyModel do
  it 'should be true' do
    expect(MyModel.new.the_truth).to eq(true)
  end
end
