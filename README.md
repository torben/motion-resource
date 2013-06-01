MotionResource: Simple JSON API Wrapper for MotionModel on RubyMotion
================

MotionResource is a simple wrapper to store your remote data in MotionModel objects. It is good for users who have a
REST API and want to have this data in an iOS app.

You need to have MotionModel ready, if you want to use this implementation: https://github.com/sxross/MotionModel


Usage
================

First of all you will need a normal MotionModel::Model:

```ruby
class Task
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns :name        => :string,
          :long_name   => :string,
          :due_date    => :date
end
```

Tune this up, by adding:
```ruby
...
include MotionResource::ApiWrapper

class MyCoolController
  def some_method
    @task = Task.create :name => 'walk the dog',
                :long_name    => 'get plenty of exercise. pick up the poop',
                :due_date     => '2012-09-15'
   end
end
```
