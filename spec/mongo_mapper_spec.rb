require File.dirname(__FILE__) + '/spec_helper'
require 'machinist/mongo_mapper'
require 'mongo_mapper'

module MachinistMongoMapperSpecs
  class ::Person
    include MongoMapper::Document
    key :_id, String
    key :password, String
    key :name,     String,  :length => (0..10)
    key :password
    key :admin,    Boolean, :default => false
  end

  class ::Admin < ::Person
    include MongoMapper::Document
  end

  class ::Post
    include MongoMapper::Document
    key :_id, String
    key :title,     String
    key :body,      String
    key :published, Boolean, :default => true
    has_many :comments
  end

  class ::Comment
    include MongoMapper::Document
    key :_id, String
    key :post_id, String
    belongs_to :post
    key :author_id, String
    belongs_to :author, :class_name => "Person"
  end

  describe Machinist, "MongoMapper adapter" do
    before(:suite) do
#       MongoMapper::Logger.new(File.dirname(__FILE__) + "/log/test.log", :debug)
      MongoMapper.connection = Mongo::Connection.new(nil, nil)
      MongoMapper.database = "machinist-tests"
    end

    before(:each) do
      [Person, Admin, Post, Comment].each(&:clear_blueprints!)
    end

    describe "make method" do
      it "should support single-table inheritance" do
        Person.blueprint { }
        Admin.blueprint  { }
        admin = Admin.make
        admin.should_not be_new_record
        admin.type.should == Admin
      end

      it "should save the constructed object" do
        Person.blueprint { }
        person = Person.make
        person.should_not be_new_record
      end

      it "should create an object through belongs_to association" do
        Post.blueprint { }
        Comment.blueprint { post }
        Comment.make.post.class.should == Post
      end

      it "should create an object through belongs_to association with a class_name attribute" do
        Person.blueprint { }
        Comment.blueprint { author }
        Comment.make.author.class.should == Person
      end

      it "should create an object through belongs_to association using a named blueprint" do
        Post.blueprint { }
        Post.blueprint(:dummy) do
          title { 'Dummy Post' }
        end
        Comment.blueprint { post(:dummy) }
        Comment.make.post.title.should == 'Dummy Post'
      end

      it "should allow creating an object through a has_many association" do
        pending
#         Post.blueprint do
#           comments { [Comment.make] }
#         end
#         Comment.blueprint { }
#         Post.make.comments.should have(1).instance_of(Comment)
      end

      it "should allow setting a protected attribute in the blueprint" do
        Person.blueprint do
          password { "Test" }
        end
        Person.make.password.should == "Test"
      end

      it "should allow overriding a protected attribute" do
        Person.blueprint do
          password { "Test" }
        end
        Person.make(:password => "New").password.should == "New"
      end

      it "should allow setting the id attribute in a blueprint" do
        Person.blueprint do
          _id { "4b6cf9eab74012333e000002" }
        end
        Person.make.id.should == "4b6cf9eab74012333e000002"
      end

      describe "on a has_many association" do
        before do
        end

        it "should save the created object" do
          pending
        end

        it "should set the parent association on the created object" do
          pending
        end
      end
    end

    describe "plan method" do
      it "should not save the constructed object" do
        person_count = Person.count
        Person.blueprint { }
        person = Person.plan
        Person.count.should == person_count
      end

      it "should create an object through a belongs_to association, and return its id" do
        Post.blueprint { }
        Comment.blueprint { post }
        post_count = Post.count
        comment = Comment.plan
        Post.count.should == post_count + 1
        comment[:post].should be_nil
        comment[:post_id].should_not be_nil
      end

      describe "on a belongs_to association" do
        it "should allow explicitly setting the association to nil" do
          Comment.blueprint { post }
          Comment.blueprint(:no_post) { post { nil } }
          lambda {
            @comment = Comment.plan(:no_post)
          }.should_not raise_error
        end
      end

      describe "on a has_many association" do
        before do
#           Post.blueprint { }
#           Comment.blueprint do
#             post
#             body { "Test" }
#           end
#           @post = Post.make
#           @post_count = Post.count
#           @comment = @post.comments.plan
        end

        it "should not include the parent in the returned hash" do
          pending
#           @comment[:post].should be_nil
#           @comment[:post_id].should be_nil
        end

        it "should not create an extra parent object" do
          pending
#           Post.count.should == @post_count
        end
      end
    end

    describe "make_unsaved method" do
      it "should not save the constructed object" do
        Person.blueprint { }
        person = Person.make_unsaved
        person.should be_new
      end

      it "should save objects made within a passed-in block" do
        Post.blueprint { }
        Comment.blueprint { }
        comment = nil
        post = Post.make_unsaved { comment = Comment.make }
        post.should be_new_record
        comment.should_not be_new
      end
    end

  end
end
