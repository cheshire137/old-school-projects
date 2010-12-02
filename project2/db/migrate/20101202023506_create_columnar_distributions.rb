class CreateColumnarDistributions < ActiveRecord::Migration
  def self.up
    create_table :columnar_distributions do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :columnar_distributions
  end
end
