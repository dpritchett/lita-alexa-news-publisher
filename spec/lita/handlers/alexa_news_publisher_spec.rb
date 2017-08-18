require "spec_helper"
require 'pry'
require 'date'

describe Lita::Handlers::AlexaNewsPublisher, lita_handler: true do
  let(:robot) { Lita::Robot.new(registry) }
  let(:jpeg_url_match) { /http.*\.jpg/i }
  let(:aliens_template_id) { 101470 }

  subject { described_class.new(robot) }

  describe 'routes' do
    it { is_expected.to route("Lita newsfeed hello, alexa!") }
  end

  describe ':save_message' do
    it 'returns a jpeg url' do
      result = subject.save_message(username: 'dpritchett', message: 'hello, alexa!')
    end
  end

  describe ':list_messages' do
  end

  it 'can grab a message from chat and store it' do
    send_message "lita newsfeed hello there #{DateTime.now}"
    response = replies.last
    expect(response =~ /hello there/i).to be_truthy
    expect(response =~ /Saved message for Alexa/).to be_truthy
  end

end
