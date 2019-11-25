class BraintreeGateway
  LOGGER = ::Logger.new(STDOUT)
  ENDPOINT = "https://payments.sandbox.braintree-api.com/graphql"
  CONTENT_TYPE = "application/json"
  VERSION = ENV["BT_VERSION"]
  BASIC_AUTH_USERNAME = ENV["BT_PUBLIC_KEY"]
  BASIC_AUTH_PASSWORD = ENV["BT_PRIVATE_KEY"]

  def initialize(requester_class)
    @requester = requester_class
  end

  def ping
    _make_request("ping", "{ ping }")
  end

  def client_token
    operation_name = "createClientToken"
    result = _make_request(operation_name, "mutation { #{operation_name}(input: {}) { clientToken } }")
  end

  def transaction(payment_method_id, amount)
    operation_name = "chargePaymentMethod"
    query = <<~GRAPHQL
    mutation($input: ChargePaymentMethodInput!) {
      #{operation_name}(input: $input) {
        transaction {
          id
        }
      }
    }
    GRAPHQL
    variables = {
      :input => {
        :paymentMethodId => payment_method_id,
        :transaction => {
          :amount => amount,
        },
      }
    }

    _make_request(operation_name, query, variables)
  end

  def vault(single_use_payment_method_id)
    operation_name = "vaultPaymentMethod"
    _make_request(
      operation_name,
      "mutation($input: VaultPaymentMethodInput!) { #{operation_name}(input: $input) { paymentMethod { id usage } } }",
      {:input => {
        :paymentMethodId => single_use_payment_method_id,
      }}
    )
  end

  def node_fetch_transaction(transaction_id)
    operation_name = "transaction"
    query = <<~GRAPHQL
    query {
      #{operation_name}:node(id: "#{transaction_id}") {
        ... on Transaction {
          id
          amount { value currencyIsoCode }
          status
          createdAt
          paymentMethodSnapshot {
            __typename
            ... on CreditCardDetails {
              bin
              brandCode
              cardholderName
              expirationMonth
              expirationYear
              last4
              binData { countryOfIssuance }
              origin { type }
            }
            ... on PayPalTransactionDetails {
              payer {
                email
                payerId
                firstName
                lastName
              }
              payerStatus
            }
          }
        }
      }
    }
    GRAPHQL
    _make_request(operation_name, query)
  end

  def _generate_payload(query_string, variables_hash)
    JSON.generate({
      :query => query_string,
      :variables => variables_hash
    }).to_s
  end

  def _make_request(operation_name, query_string, variables_hash = {})
    # rescue http exceptions thrown by httparty and throw a GraphQLError
    payload = _generate_payload(query_string, variables_hash)
    result = @requester.post(
      ENDPOINT,
      {
        :body => payload,
        :basic_auth => {
          :username => BASIC_AUTH_USERNAME,
          :password => BASIC_AUTH_PASSWORD,
        },
        :headers => {
          "Braintree-Version" => VERSION,
          "Content-Type" => CONTENT_TYPE,
        },
        :logger => LOGGER,
        :log_level => :debug,
      }
    ).parsed_response
    is_any_data_present = (result["data"] != nil and result["data"][operation_name] != nil)

    if result["errors"]
      LOGGER.error(
        <<~SEMISTRUCTUREDLOG
        "top_level_message" => "Error present on GraphQL request to Braintree.",
        "operation_name" => #{operation_name},
        "braintree_request_id" => #{self.class.parse_braintree_request_id(result)},
        "result" => #{result},
        "request" => #{payload}"
        SEMISTRUCTUREDLOG
      )
    end

    if is_any_data_present
      return result
    else
      raise GraphQLError.new(result)
    end
  end

  def self.parse_braintree_request_id(result)
    result.dig("extensions", "requestId")
  end

  class GraphQLError < StandardError
    attr_reader :messages
    def initialize(graphql_result)
      @messages = graphql_result["errors"].map { |error| "Error: " + error["message"] } if graphql_result["errors"]

      LOGGER.error(
        <<~SEMISTRUCTUREDLOG
        "top_level_message" => #{@messages.to_s},
        "braintree_request_id" => #{BraintreeGateway.parse_braintree_request_id(graphql_result)},
        "result" => #{graphql_result},
        SEMISTRUCTUREDLOG
      )
    end
  end
end
