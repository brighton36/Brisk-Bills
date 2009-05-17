class CreateActivityMaterials < ActiveRecord::Migration
  def self.up
    create_table :activity_materials, :options => 'TYPE=InnoDB' do |t|
      
      t.integer :activity_id
      t.string  :label
      t.text    :comments

      t.timestamps
    end
  end

  def self.down
    drop_table :activity_materials
  end
end
