namespace :db do
  
  desc "Copies the example database into persever."
  task :copy_example_to_persever => :environment do
    DataMapper::Reflection.setup(:binding => binding, :database => :example)
    DataMapper::Reflection.create_models_from_database

    [Warehouse, Customer, OrderLine, Order, Item, History, NewOrder, Stock, District].each do |model|
      collection = model.all
      repository(:yogo).adapter.put_schema(model.send(:to_json_schema_compatable_hash))
      repository(:yogo) do
        collection.each{|item| model.create!(item.attributes) }
      end
    end

  end
end

# desc "Yogo specific database preparation task"
# task 'db:test:prepare' do
#   
# end