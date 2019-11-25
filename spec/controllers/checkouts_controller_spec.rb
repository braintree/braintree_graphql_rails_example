require 'rails_helper'
require 'support/mock_data'

RSpec.describe CheckoutsController, type: :controller do
  render_views
  include_context 'mock_data'

  before do
    @mock_gateway = instance_double("BraintreeGateway")
    allow(@mock_gateway).to receive(:client_token).and_return({
      "data" => {
        "createClientToken" => {
          "clientToken" => "your_client_token"
        }
      }
    })

    allow(BraintreeGateway).to receive(:new).and_return(@mock_gateway)
  end

  describe "GET #new" do
    it "returns http success" do
      get :new
      expect(response).to have_http_status(:success)
    end

    it "adds the Braintree client token to the page" do
      get :new
      expect(response.body).to match /your_client_token/
    end
  end

  describe "GET #show" do
    it "returns http success" do
      allow(@mock_gateway).to receive(:node_fetch_transaction).and_return(mock_successful_fetched_transaction)

      get :show, params: { id: "my_id" }

      expect(response).to have_http_status(:success)
    end

    it "displays the transaction's fields" do
      allow(@mock_gateway).to receive(:node_fetch_transaction).and_return(mock_successful_fetched_transaction)

      get :show, params: { id: "my_id" }

      expect(response.body).to match /my_id/
      expect(response.body).to match /12\.12/
      expect(response.body).to match /CAD/
      expect(response.body).to match /SUBMITTED_FOR_SETTLEMENT/
      expect(response.body).to match /545454/
      expect(response.body).to match /4444/
      expect(response.body).to match /Billy Bobby Pins/
      expect(response.body).to match /12/
      expect(response.body).to match /2020/
      expect(response.body).to match /USA/
    end

    it "populates result object with success for a succesful transaction" do
      allow(@mock_gateway).to receive(:node_fetch_transaction).and_return(mock_successful_fetched_transaction)

      get :show, params: { id: "my_id" }

      expect(assigns(:result)).to eq({
        :header => "Sweet Success!",
        :icon => "success",
        :message => "Your test transaction has been successfully processed. See the Braintree API response and try again."
      })
    end


    it "populates result object with failure for a failed transaction" do
      allow(@mock_gateway).to receive(:node_fetch_transaction).and_return(mock_processor_decline_fetched_transaction)

      get :show, params: { id: "my_id" }

      expect(assigns(:result)).to eq({
        :header => "Transaction Unsuccessful",
        :icon => "fail",
        :message => "Your test transaction has a status of PROCESSOR_DECLINED. See the Braintree API response and try again."
      })
      expect(response.body).to match /PROCESSOR_DECLINED/
    end
  end

  describe "POST #create" do
    it "returns http success" do
      amount = "10.00"
      nonce = "fake-valid-nonce"

      allow(@mock_gateway).to receive(:transaction).and_return(mock_created_transaction)

      post :create, params: { payment_method_nonce: nonce, amount: amount }

      expect(response).to redirect_to("/checkouts/#{mock_created_transaction["data"]["chargePaymentMethod"]["transaction"]["id"]}")
    end

    context "when braintree returns an error" do
      it "displays graphql errors" do
        amount = "nine and three quarters"
        nonce = "fake-valid-nonce"

        allow(@mock_gateway).to receive(:transaction).and_raise(
          BraintreeGateway::GraphQLError.new(mock_transaction_graphql_error)
        )

        post :create, params: { payment_method_nonce: nonce, amount: amount }

        expect(flash[:error]).to eq([
          "Error: Variable 'amount' has an invalid value. Values of type Amount must contain exactly 0, 2 or 3 decimal places."
        ])
      end

      it "displays validation errors" do
        amount = "9.75"
        nonce = "non-fake-invalid-nonce"

        allow(@mock_gateway).to receive(:transaction).and_raise(
          BraintreeGateway::GraphQLError.new(mock_transaction_validation_error)
        )

        post :create, params: { payment_method_nonce: nonce, amount: amount }

        expect(flash[:error]).to eq([
          "Error: Unknown or expired payment method ID.",
        ])
      end

      it "redirects to the new_checkout_path" do
        amount = "not_a_valid_amount"
        nonce = "not_a_valid_nonce"

        allow(@mock_gateway).to receive(:transaction).and_raise(
          BraintreeGateway::GraphQLError.new(mock_transaction_graphql_error)
        )

        post :create, params: { payment_method_nonce: nonce, amount: amount }

        expect(response).to redirect_to(new_checkout_path)
      end

      it "gracefully handles unexpected errors" do
        amount = "10.10"
        nonce = "a-very-valid-nonce"

        allow(@mock_gateway).to receive(:transaction).and_raise(
          BraintreeGateway::GraphQLError.new({
            "data" => nil,
            "errors" => nil,
          })
        )

        post :create, params: { payment_method_nonce: nonce, amount: amount }

        expect(flash[:error]).to eq([
          "Error: Something unexpected went wrong! Try again."
        ])
        expect(response).to redirect_to(new_checkout_path)
      end
    end
  end
end
