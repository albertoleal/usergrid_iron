describe Usergrid::Collection do

  before :all do
    @application = create_random_application
    @user = create_random_user @application, true

    @collection = @application['tests'].collection
    @entity_data = (1..25).collect do |i|
      { name: "name_#{i}", value: "value_#{i+1}" }
    end
    (1..3).each {|i| @entity_data[i]['three'] = 3}
    @collection.create_entities @entity_data
  end

  after :all do
    @user.delete
    delete_application @application
  end

  it "should be able to do a simple query" do
    @collection.query "select * where name = \'#{@entity_data[0][:name]}\'"
    @collection.size.should eq 1
  end

  it "should be able to select data elements" do
    @collection.query "select name, value where name = \'#{@entity_data[0][:name]}\'"
    @collection.size.should eq 1
    # note: not Usergrid::Entity objects: it is an Array for this kind of query
    values = @collection.entities.first
    values[0].should eq @entity_data[0][:name]
    values[1].should eq @entity_data[0][:value]
  end

  it "should be able to select redefined data elements" do
    @collection.query "select { test1: name, test2 : value } where name = \'#{@entity_data[0][:name]}\'"
    @collection.size.should eq 1
    # note: not Usergrid::Entity objects: it is a Hash for this kind of query
    values = @collection.entities.first
    values.test1.should eq @entity_data[0][:name]
    values.test2.should eq @entity_data[0][:value]
  end

  it "should be able to find an entity" do
    @collection.query
    entity = @collection.detect { |e| e.name == @entity_data[5][:name] }
    entity.should_not be_nil
    entity.name.should eq @entity_data[5][:name]
  end

  it "should be able to respect query reversal and limits" do
    @collection.query nil, reversed: true, start: 5, cursor: nil, limit: 2, permission: nil
    @collection.size.should eq 2
    @collection[0].name.should eq @entity_data[@entity_data.size-1][:name]
    @collection[1].name.should eq @entity_data[@entity_data.size-2][:name]
  end

  it "should be able to select the start by uuid" do
    @collection.query
    uuid = @collection[4].uuid
    @collection.query nil, reversed: false, start: uuid, cursor: nil, limit: 3, permission: nil
    @collection.size.should eq 3
    @collection.first.uuid.should eq uuid
    @collection[2].name.should eq @entity_data[6][:name]
  end

  it "should be able to page forward by cursor" do
    @collection.query 'select * where three = 3', limit: 2
    @collection.next_page
    @collection.size.should eq 1
    @collection[0].name.should eq @entity_data[3][:name]
  end

  it "should be able to update based on a query" do
    @collection.update_query({new_field: 'new_value'}, "select * where name = \'#{@entity_data[4][:name]}\'")
    @collection.query
    entity = @collection.detect { |e| e['new_field'] == 'new_value' }
    entity.should_not be_nil
    entity.name.should eq @entity_data[4][:name]
  end

  it "should be able to iterate within the page" do
    @collection.query
    @collection.cursor.should_not be_nil
    count = 0
    page_size = @collection.count
    @collection.each {|e| count += 1 }
    count.should eq page_size
  end

  it "should be able to iterate over pages" do
    @collection.query
    @collection.cursor.should_not be_nil
    count = 0
    @collection.follow_cursor.each {|e| count += 1 }
    count.should eq @entity_data.size
  end

end
