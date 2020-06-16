class CreateTovs < ActiveRecord::Migration[5.2]
  def change
    create_table :tovs do |t|
      t.string :fid
      t.string :link
      t.string :sku
      t.string :title
      t.string :sdesc
      t.string :desc
      t.string :oldprice
      t.string :price
      t.string :pict
      t.string :cat
      t.string :cat1
      t.string :cat2
      t.string :cat3
      t.string :mtitle
      t.string :mdesc
      t.string :mkeyw
      t.string :p1
      t.string :p2
      t.string :p3
      t.string :p4
      t.boolean :label
      t.boolean :check
      t.string :linkins
      t.string :insid

      t.timestamps
    end
  end
end
