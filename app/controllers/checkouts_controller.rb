class CheckoutsController < ApplicationController
  TRANSACTION_SUCCESS_STATUSES = [
    "AUTHORIZED",
    "AUTHORIZING",
    "SETTLED",
    "SETTLEMENT_PENDING",
    "SETTLING",
    "SUBMITTED_FOR_SETTLEMENT",
  ]

  def new
    @client_token = gateway.client_token.dig("data", "createClientToken", "clientToken")
  end

  def show
    begin
      @transaction = gateway.node_fetch_transaction(params[:id]).fetch("data", {})["transaction"]
      @result = _create_status_result_hash(@transaction)
    rescue BraintreeGateway::GraphQLError => error
      _flash_errors(error)
      redirect_to new_checkout_path
    end
  end

  def create
    amount = params["amount"] # In production you should not take amounts directly from clients
    nonce = params["payment_method_nonce"]

    begin
      result = gateway.transaction(nonce, amount)
      id = result.dig("data", "chargePaymentMethod", "transaction", "id")

      if id
        redirect_to checkout_path(id)
      else
        raise BraintreeGateway::GraphQLError.new(result)
      end
    rescue BraintreeGateway::GraphQLError => error
      _flash_errors(error)
      redirect_to new_checkout_path
    end
  end

  def _create_status_result_hash(transaction)
    status = transaction["status"]

    if TRANSACTION_SUCCESS_STATUSES.include? status
      result_hash = {
        :header => "Sweet Success!",
        :icon => "success",
        :message => "Your test transaction has been successfully processed. See the Braintree API response and try again."
      }
    else
      result_hash = {
        :header => "Transaction Unsuccessful",
        :icon => "fail",
        :message => "Your test transaction has a status of #{status}. See the Braintree API response and try again."
      }
    end
  end

  def _flash_errors(error)
    if error.messages != nil and !error.messages.empty?
      flash[:error] = error.messages
    else
      flash[:error] = ["Error: Something unexpected went wrong! Try again."]
    end
  end

  def gateway
    @gateway ||= BraintreeGateway.new(HTTParty)
  end
end
