class CreateTeams < ActiveRecord::Migration[7.1]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.references :group, null: false, foreign_key: true
      t.integer :points, null: false, default: 0
      t.integer :goals_for, null: false, default: 0
      t.integer :goals_against, null: false, default: 0
      t.integer :goal_difference, null: false, default: 0
      t.integer :matches_played, null: false, default: 0
      t.integer :wins, null: false, default: 0
      t.integer :draws, null: false, default: 0
      t.integer :losses, null: false, default: 0

      t.timestamps
    end

    # Índice compuesto para ordenar la tabla de posiciones eficientemente
    add_index :teams, [:group_id, :points, :goal_difference, :goals_for],
              name: "idx_teams_standings"
  end
end
