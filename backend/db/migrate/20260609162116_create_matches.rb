class CreateMatches < ActiveRecord::Migration[7.1]
  def change
    create_table :matches do |t|
      t.references :tournament, null: false, foreign_key: true
      # group_id permite NULL: los partidos de eliminatoria no pertenecen a un grupo
      t.references :group, null: true, foreign_key: true
      # home_team y away_team apuntan ambos a la tabla teams
      t.references :home_team, null: false, foreign_key: { to_table: :teams }
      t.references :away_team, null: false, foreign_key: { to_table: :teams }
      t.integer :home_goals, default: 0
      t.integer :away_goals, default: 0
      t.integer :home_extra_goals, default: 0
      t.integer :away_extra_goals, default: 0
      t.integer :home_penalties, default: 0
      t.integer :away_penalties, default: 0
      t.string :phase, null: false
      t.integer :round_number
      t.string :status, null: false, default: "scheduled"

      t.timestamps
    end

    add_index :matches, :phase
  end
end
