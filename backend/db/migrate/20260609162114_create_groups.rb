class CreateGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.references :tournament, null: false, foreign_key: true

      t.timestamps
    end

    add_index :groups, [:name, :tournament_id], unique: true
  end
end
