class FakeDelegate
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