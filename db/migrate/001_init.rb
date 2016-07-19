class Init < ActiveRecord::Migration[5.0]
  def change
    create_table :ips do |t|
      t.string :address
      t.boolean :on, :default => true

      t.timestamps
    end

    create_table :pings do |t|
      t.belongs_to :ip, foreign_key: true
      t.string :rtt
      t.boolean :timeout
      t.boolean :noroute

      t.timestamps
    end
  end
end
