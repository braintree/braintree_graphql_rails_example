require 'rails_helper'
require 'support/mock_data'

RSpec.describe BraintreeGateway do
  include_context 'mock_data'

  before do
    mock_requester = class_double(HTTParty)
    @mock_response = double("Response")
    allow(mock_requester).to receive(:post).and_return(@mock_response)

    @gateway = BraintreeGateway.new(mock_requester)
  end

  describe "error handling" do
    it "throws a GraphQLError for nil data" do
      empty = {"data" => nil, "errors" => [{"message" => "an error message"}], "extensions" => {"requestId" => "not-a-real-request-1"}}
      expect(@mock_response).to receive(:parsed_response).and_return(empty)

      expect { @gateway.ping }.to raise_exception(BraintreeGateway::GraphQLError)
    end

    it "throws a GraphQLError when the expected data key is nil" do
      empty = {"data" => {"ping" => nil}, "errors" => [{"message" => "another error message"}], "extensions" => {"requestId" => "not-a-real-request-2"}}
      expect(@mock_response).to receive(:parsed_response).and_return(empty)

      expect { @gateway.ping }.to raise_exception(BraintreeGateway::GraphQLError)
    end
  end

end
