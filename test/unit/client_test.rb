require 'test_helper'

class ClientTest < ActiveSupport::TestCase
  # Ensure we can create and delete the clients table when using a valid schema
  test "table creation and deletion" do
    schema = "lname:varchar(25);lClass:varchar(2);fname:varchar(25);
      fClass:varchar(2);amount:numeric(7,2);aClass:varchar(2);
      jurisdiction:varchar(25);jclass:varchar(2)*
      al-gamal;C;selim;C;12,322.00;S;germany;S*
      bosch;C;hendrik;C;14,073.00;C;netherlands;C*
      ivanov;C;alexander;C;24,016.00;TS;germany;S*
      schmidt;C;johann;C;22,400.32;TS;germany;S*
      smith;C;john;C;15,000.17;S;australia;TS*"
    client = Client.new(schema)
    client.create_table
    assert Client.table_exists?
    Client.drop_table
    assert !Client.table_exists?
  end
  
  # Ensure we cannot get a new Client instance when using a schema with an
  # invalid column type
  test "invalid column type" do
    schema = "lname:enum('a', 'b', 'c');lClass:varchar(2)*al-gamal;C*"
    assert_raise RuntimeError do
      Client.new(schema)
    end
  end
  
  test "marek run_query" do
    # Create tables, load data
    client = Client.new "lname:varchar(25);lClass:varchar(2);fname:varchar(25);
      fClass:varchar(2);amount:numeric(7,2);aClass:varchar(2);
      jurisdiction:varchar(25);jclass:varchar(2)*
      al-gamal;C;selim;C;12,322.00;S;germany;S*
      bosch;C;hendrik;C;14,073.00;C;netherlands;C*
      ivanov;C;alexander;C;24,016.00;TS;germany;S*
      schmidt;C;johann;C;22,400.32;TS;germany;S*
      smith;C;john;C;15,000.17;S;australia;TS*"
    ul = UserLevel.new "name:varchar(25);class:varchar(2)*
      alice;U*baxter;TS*dexter;S*marek;C*"
    client.create_table
    ul.create_table
    client.load_data
    ul.load_data
    
    # Ensure we get back expected number of rows, and that marek cannot read
    # john smith's jurisdiction--should come back as nil
    query = "SELECT lname, fname, jurisdiction FROM Clients
      WHERE amount BETWEEN 14000 AND 20000"
    gen_query, rows, columns = client.run_query('marek', query)
    assert_equal 2, rows.length
    assert_equal nil, rows[1]['jurisdiction']
    
    # Destroy tables
    UserLevel.drop_table
    Client.drop_table
  end
end
