Dotenv.load

if !ENV["BT_PUBLIC_KEY"] || !ENV["BT_PRIVATE_KEY"] || !ENV["BT_VERSION"]
  raise "Cannot find necessary environmental variables. See https://github.com/braintree/braintree_graphql_rails_example#setup-instructions for instructions";
end
