require 'test_helper'

class ColumnarDistributionTest < ActiveSupport::TestCase
  # Ensure we can create and delete the clients table when using a valid schema
  test "table creation and deletion" do
    schema = "lname:varchar(25);lClass:varchar(2)*
      al-gamal;C*
      bosch;C*"
    cd = ColumnarDistribution.new(schema)
    cd.create_tables
    cd.tables.each do |table|
      assert table.table_exists?
    end
    cd.drop_tables
    cd.tables.each do |table|
      assert !table.table_exists?
    end
  end
  
  # Ensure we cannot get a new ColumnarDistribution instance when using a schema
  # with an invalid column type
  test "invalid column type" do
    schema = "lname:enum('a', 'b', 'c');lClass:varchar(2)*al-gamal;C*"
    assert_raise RuntimeError do
      ColumnarDistribution.new(schema)
    end
  end
  
  test "run a query" do
    schema = "person:varchar(16);money:numeric(7,2);state:varchar(2)*
      sarah;5000;ky*
      jon;13,300.52;ky*
      sarah;3200;tn*
      sarah;1400.25;ny*
      jon;4000;ky*
      sarah;12.50;fl*"
    cd = ColumnarDistribution.new(schema)
    cd.create_tables
    cd.load_data
    query = "SELECT person, SUM(money) FROM blah WHERE state='ky' GROUP BY person"
    gen_query, rows, cols = cd.run_query(query)
    # Should get 2 rows back because only 3 rows fit the WHERE clause, and of
    # those three, there are only 2 unique values for 'person', the GROUP BY
    # clause:
    assert_equal 2, rows.length, "Expected 2 rows to be returned"
    cd.drop_tables
  end
end
