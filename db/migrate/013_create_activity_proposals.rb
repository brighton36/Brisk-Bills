class CreateActivityProposals < ActiveRecord::Migration
  def self.up
    create_table :activity_proposals, :options => 'TYPE=InnoDB' do |t|
      
      t.integer   :activity_id
      
      t.string    :label
      t.text      :comments
      t.timestamp :proposed_on

      t.timestamps
    end
  end

  def self.down
    drop_table :activity_proposals
  end
end
