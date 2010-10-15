require 'test_helper'

class UserLevelTest < ActiveSupport::TestCase
  # Ensure we can create and delete the user_levels table
  test "table creation and deletion" do
    schema = "name:varchar(25);class:varchar(2)*alice;U*baxter;TS*dexter;S*marek;C*"
    ul = UserLevel.new(schema)
    ul.create_table
    assert UserLevel.table_exists?
    UserLevel.drop_table
    assert !UserLevel.table_exists?
  end
  
  # Ensure we cannot get a new UserLevel instance when using a schema with an
  # invalid column type
  test "invalid column type" do
    schema = "name:numeric(3,1);class:tinyint(1)*"
    assert_raise RuntimeError do
      UserLevel.new(schema)
    end
  end
  
  # Ensure we cannot get a new UserLevel instance when using a schema that is
  # missing the 'class' column
  test "missing class column" do
    schema = "name:varchar(100)*"
    assert_raise RuntimeError do
      UserLevel.new(schema)
    end
  end
end
