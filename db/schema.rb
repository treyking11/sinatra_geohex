require_relative "connection"

ActiveRecord::Schema.define do
  create_table :address, force: :cascade do |t|
    t.string :name
    t.string :address
    t.string :city
    t.string :state
    t.number :zip
    t.number :radius
  end
end
