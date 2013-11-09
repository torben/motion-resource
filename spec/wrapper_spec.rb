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
    before do
      3.times { User.create }
      Task.create(id: 22)
      Task.create(id: 33)
    end

    describe '#updateModels' do
      it 'should return nil, if model has no updated_at column' do
        User.lastUpdate.should == nil
      end

      it 'should return last updated_at, if model has updated_at column' do
        Task.lastUpdate.to_s.should.equal Task.find(33).updated_at.to_s
      end
    end

    describe '#touchSync' do
      it 'should sets a timestap when calling' do
        u = User.new
        u.touchSync
        u.lastSyncAt.class.should == Time
      end

      it 'should return nil if model has no lastSyncAt column' do
        t = Task.new
        t.touchSync.should == nil
      end
    end
  end
end