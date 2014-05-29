class UserWithOutWrapper
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  include MotionModelResource::ApiWrapper
  columns       name:   :string,
                email:  :string,
                age:    :integer,
                admin:  :boolean
end

class User
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  include MotionModelResource::ApiWrapper

  def self.url
    "http://example.com/users"
  end

  def self.wrapper
    @wrapper ||= {
      fields: {
        id:       :id,
        plan_id:  :plan_id,
        name:     :name,
        email:    :email,
        age:      :age,
        admin:    :admin
      },
      relations: [:tasks, :plan]
    }
  end

  columns name:       :string,
          plan_id:    :plan_id,
          email:      :string,
          age:        :integer,
          admin:      :boolean,
          lastSyncAt: :time

  has_many :tasks
  belongs_to :plan
end

class Task
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  include MotionModelResource::ApiWrapper

  def self.url
    "http://example.com/tasks"
  end

  def self.wrapper
    @wrapper ||= {
      fields: {
        id:       :id,
        user_id:  :user_id,
        name:     :name,
      },
      relations: [:user]
    }
  end

  columns name:       :string,
          due_date:   :time,
          updated_at: :date
  belongs_to :user
end

class Plan
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  include MotionModelResource::ApiWrapper

  def self.url
    "http://example.com/plans"
  end

  def self.wrapper
    @wrapper ||= {
      fields: {
        id:       :id,
        name:     :name,
      },
      relations: [:users]
    }
  end

  columns name: :string
  has_many :users
end

class PlanWithoutUrl
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter
  include MotionModelResource::ApiWrapper

  def self.wrapper
    @wrapper ||= {
      fields: {
        id:       :id,
        name:     :name,
      },
      relations: [:users]
    }
  end

  columns name: :string
end

describe "Fetching a model" do
  extend WebStub::SpecHelpers

  it "should not wrap a model without wrapper method" do
    lambda{
      UserWithOutWrapper.fetch("http://localhost:3000/users/1")
    }.should.raise(MotionModelResource::WrapperNotDefinedError)
  end

  it "should create a new model with API call" do
    user_url = "http://localhost:3000/users/1"
    stub_request(:get, user_url).to_return(json: {
      name:  "Peter",
      email: "peter@pan.de",
      age:   14,
      admin: false
    })

    User.fetch(user_url) do |model|
      resume
    end

    wait_max 1.0 do
      user = User.first
      user.should.not == nil
      User.count.should.equal(1)
      user.name.should.equal("Peter")
      user.email.should.equal("peter@pan.de")
      user.age.should.equal(14)
      user.admin.should.equal(false)
      user.lastSyncAt.should.not == nil
    end
  end

  it "should create a new model with dependencies" do
    User.delete_all
    Task.delete_all
    Plan.delete_all

    user_url = "http://localhost:3000/users/10"
    stub_request(:get, user_url).to_return(json: {
      id: 10,
      plan_id: 5,
      name:  "Manuel",
      email: "manuel@dudda.de",
      age:   28,
      admin: true,
      tasks: [
        {
          id: 1,
          name: 'Cleaning up the closet',
          user_id: 10
        },
        {
          id: 2,
          name: 'Drinking soda',
          user_id: 10
        }
      ],
      plan: {
        id: 5,
        name: 'Gold'
      }
    })

    User.fetch(user_url) do |model|
      resume
    end

    wait_max 1.0 do
      User.count.should.equal(1)
      Plan.count.should.equal(1)
      Task.count.should.equal(2)

      user = User.find(10)
      user.plan.name.should.equal("Gold")
      user.tasks.first.name.should.equal("Cleaning up the closet")
      user.tasks.last.name.should.equal("Drinking soda")
    end
  end

  describe 'Class Methods' do
    describe '#build_model_with' do
      it 'should build a new Task object' do
        json = {
          "id" => 929,
          "name" => 'Cleaning up the closet',
          "user_id" => 10
        }

        t = Task.build_model_with(json)

        t.name.should == "Cleaning up the closet"
        t.user_id.should == 10
        t.class == Task
        t.new_record?.should == true

        t.save
      end

      it 'should return and update an existing model' do
        json = {
          "id" => 929,
          "name" => 'A new name',
          "user_id" => 10
        }

        t = Task.build_model_with(json)

        t.name.should == "A new name"
        t.user_id.should == 10
        t.class == Task
        t.new_record?.should == false
      end

      it 'should retun nil, if array is given' do
        json = [{
          id: 923,
          name: 'Cleaning up the closet',
          user_id: 10
        },
        {
          id: 924,
          name: 'Cleaning up the closet2',
          user_id: 11
        }]

        Task.build_model_with(json).should == nil
      end
    end

    describe '#create_model_with' do
      it 'should create a new Task object' do
        json = {
          "id" => 828,
          "name" => 'An Amazing Name!',
          "user_id" => 12
        }

        t = Task.save_model_with(json)

        t.name.should == "An Amazing Name!"
        t.user_id.should == 12
        t.class == Task
        t.new_record?.should == false
      end

      it 'should return and update an existing model' do
        json = {
          "id" => 828,
          "name" => 'A newer name',
          "user_id" => 12
        }

        t = Task.save_model_with(json)
        t.new_record?.should == false

        t2 = Task.find(828)
        t2.name.should == "A newer name"
        t2.user_id.should == 12
        t2.class == Task
      end

      it 'should retun nil, if array is given' do
        json = [{
          id: 923,
          name: 'Cleaning up the closet',
          user_id: 10
        },
        {
          id: 924,
          name: 'Cleaning up the closet2',
          user_id: 11
        }]

        Task.build_model_with(json).should == nil
      end
    end

    describe '#update_models' do
      before do
        3.times { User.create }
        Task.create(id: 22)
        Task.create(id: 33)
      end

      it 'should return nil, if model has no updated_at column' do
        User.last_update.should == nil
      end

      it 'should return last updated_at, if model has updated_at column' do
        Task.last_update.to_s.should.equal Task.find(33).updated_at.to_s
      end
    end

    describe '#touch_sync' do
      it 'should sets a timestap when calling' do
        u = User.new
        u.touch_sync
        u.lastSyncAt.class.should == Time
      end

      it 'should return nil if model has no lastSyncAt column' do
        t = Task.new
        t.touch_sync.should == nil
      end
    end
  end

  describe 'Instance Methods' do
    describe '#parse_value' do
      it 'should parse a date string to a time string' do
        t = Task.new
        t.parse_value(:due_date, "2014-05-29T10:59:39+02:00").should == "2014-05-29 08:59:39 +0000"
      end

      it 'should return nil if the input date is invalid' do
        t = Task.new
        t.parse_value(:due_date, "2014-05-29 10:59:39").should == nil
      end
    end

    describe '#save' do
      it 'should return nil, if the remote server returns empty json' do
        stub_request(:post, Task.url).to_return(json: {})
        t = Task.new
        t.name = "This is Sparta!"

        new_model = nil
        t.save do |model|
          resume
          new_model = model
        end

        wait_max 1.0 do
          new_model.should == nil
        end
      end

      it 'should save a model and call the remote server' do
        stub_request(:post, Task.url).to_return(json: {name: 'This is Sparta!'})
        t = Task.new
        t.name = "This is Sparta!"

        @new_model = nil
        t.save do |model|
          @new_model = model
          resume
        end

        wait_max 1.0 do
          @new_model.should.not == nil
          @new_model.new_record?.should == false
          @new_model.name.should == "This is Sparta!"
        end
      end

      it 'should update a model and call the remote server' do
        t = Task.last
        t.name = "This was Sparta :("
        stub_request(:put, "#{Task.url}/#{t.id}").to_return(json: {name: 'This was Sparta :('})

        @update_model = nil
        t.save do |model|
          @update_model = model
          resume
        end

        wait_max 1.0 do
          @update_model.should.not == nil
          @update_model.new_record?.should == false
          @update_model.name.should == "This was Sparta :("
        end
      end
    end

    describe '#save_action' do
      it 'should return :create, when having a new record' do
        t = Task.new
        t.send(:save_action).should == :create
      end

      it 'should return :update, when having a new record' do
        t = Task.last
        t.send(:save_action).should == :update
      end

      it 'should raise an exception, when having a new record with an id' do
        t = Task.last
        t.id = nil
        lambda {
          t.send(:save_action)
        }.should.raise(MotionModelResource::ActionNotImplemented)
      end
    end

    describe '#save_url' do
      it 'should raise an exception, when url property is missing' do
        p = PlanWithoutUrl.new
        lambda {
          p.send(:save_url)
        }.should.raise(MotionModelResource::URLNotDefinedError)
      end

      it 'should return the right create url' do
        t = Task.new
        t.send(:save_url).should == Task.url
      end

      it 'should return the right update url' do
        t = Task.first
        t.send(:save_url).should == "#{Task.url}/#{t.id}"
      end
    end
  end
end