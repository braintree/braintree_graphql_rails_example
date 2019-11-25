RSpec.shared_context 'mock_data' do

  let(:mock_successful_fetched_transaction) {
    {
      "data" => {
        "transaction" => {
          "id" => "my_id",
          "amount" => {
            "value" => "12.12",
            "currencyIsoCode" => "CAD",
          },
          "status" => "SUBMITTED_FOR_SETTLEMENT",
          "createdAt" => "2019-08-07T15:47:54.000000Z",
          "paymentMethodSnapshot" =>  {
            "__typename" => "CreditCardDetails",
            "bin" => "545454",
            "brandCode" => "MASTERCARD",
            "cardholderName" => "Billy Bobby Pins",
            "expirationMonth" => "12",
            "expirationYear" => "2020",
            "last4" => "4444",
            "binData" => {
              "countryOfIssuance" => "USA",
            },
            "origin" => nil,
          },
        }
      },
      "extensions" => {
        "requestId" => "abc-request-123-id"
      }
    }
  }

  let(:mock_processor_decline_fetched_transaction) {
    {
      "data" => {
        "transaction" => {
          "id" => "spaceodyssey",
          "amount" => {
            "value" => "2001.00",
            "currencyIsoCode" => "USD",
          },
          "status" => "PROCESSOR_DECLINED",
          "gatewayRejectionReason" => nil,
          "processorResponse" => {
            "legacyCode" => "2001",
            "message" => "Insufficient Funds",
          },
          "paymentMethodSnapshot" =>  {
            "__typename" => "CreditCardDetails",
            "bin" => "545454",
            "brandCode" => "MASTERCARD",
            "cardholderName" => "Billy Bobby Pins",
            "expirationMonth" => "12",
            "expirationYear" => "2020",
            "last4" => "4444",
            "binData" => {
              "countryOfIssuance" => "USA",
            },
            "origin" => nil,
          },
        }
      },
      "extensions" => {
        "requestId" => "def-request-456-id"
      }
    }
  }

  let(:mock_created_transaction) {
    {
      "data" => {
        "chargePaymentMethod" => {
          "transaction" => {
            "id" => "my_id"
          }
        }
      }
    }
  }

  let(:mock_transaction_validation_error) {
    {
      "data" => {
        "chargePaymentMethod" => nil,
      },
      "errors" => [
        {
          "message" => "Unknown or expired payment method ID.",
          "locations" => [
            {
              "line" => 2,
              "column" => 3
            }
          ],
          "path" => [
            "chargePaymentMethod"
          ],
          "extensions" => {
            "errorType" => "user_error",
            "errorClass" => "VALIDATION",
            "legacyCode" => "91565",
            "inputPath" => [
              "input",
              "transaction",
              "singleUseTokenId"
            ]
          }
        }
      ],
      "extensions" => {
        "requestId" => "ghi-request-789-id"
      }
    }
  }

  let(:mock_transaction_graphql_error) {
    {
      "data" => nil,
      "errors" => [
        {
          "message" => "Variable 'amount' has an invalid value. Values of type Amount must contain exactly 0, 2 or 3 decimal places.",
          "locations" => [
            {
              "line" => 1,
              "column" => 11
            }
          ]
        }
      ],
      "extensions" => {
        "requestId" => "jkl-request-012-id"
      }
    }
  }
end
