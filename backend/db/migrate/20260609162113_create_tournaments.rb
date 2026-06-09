class CreateTournaments < ActiveRecord::Migration[7.1]
  def change
    create_table :tournaments do |t|
      t.string :name, null: false
      t.string :status, null: false, default: "setup"

      t.timestamps
    end
  end
end
