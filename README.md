MotionModelResource: Simple JSON API Wrapper for MotionModel on RubyMotion
==========================================================================

MotionModelResource is a simple wrapper to store your remote data in MotionModel objects. It is good for users who have a
REST API and want to have it in an iOS app.

You need to have MotionModel ready, if you want to use this implementation: https://github.com/sxross/MotionModel


### Overview
* [Installation](#installation)
* [Setup](#setup)
* [Usage](#usage)


Installation
------------
Add the following line to your `Gemfile`:

`gem "motion_model_resource"`

You need to require the Gem. Insert the
following immediately before `Motion::Project::App.setup`:

```ruby
require 'motion_model' # If you haven't already
require 'motion_model_resource'
```

Then, update your bundle:

`bundle`


Setup
-----

First of all you will need a normal MotionModel::Model:

```ruby
class Task
  include MotionModel::Model
  include MotionModel::ArrayModelAdapter

  columns name:         :string,
          long_name:    :string,
          due_date:     :date,
          lastSyncedAt: :time
end
```

Tune this up, by adding:
```ruby
...
  include MotionModelResource::ApiWrapper

  def self.url
    "https://example.com/tasks"
  end

  def self.wrapper
    @wrapper ||= {
      fields: {
        id:         :id,
        name:       :name,
        long_name:  :long_name,
        due_date:   :due_date
      },
      relations: [:user]
    }
  end
...
```
The wrapper hash has two main keys. The first one is "fields". Here you specify the local and remote keys, you want to have from your API response. The hash-key is the remote key and the hash-value is the local key. It is used, if you have different names in your implementation (maybe camelcase with underscore).
The second key in the main hash is the "relations" part. Here you can specify the wanted relations from your remote response. It will automatacally look after the right relation, for example if you have a relation "tasks", and the response is an array, it will create a bunch of tasks for you.

The url method will be used for saving a remote model. Maybe in future for a routes prefix.


Usage
-----

### Getting Remote Models

Fetching your API by calling "fetch" on your model class:

```ruby
Task.fetch("https://example.com/tasks")
```

**Example Response**
```javascript
[{
  "id": 1,
  "name": 'Buy beer',
  "long_name": 'Many, many, many beer!',
  "due_date": "2013-11-03T20:40:00+01:00",
  "updated_at": "2013-11-03T20:20:10+01:00",
  "created_at": "2013-11-03T20:06:01+01:00"
},{
  "id": 2,
  "name": 'Drink beer',
  "long_name": 'Beer, beer, beer, beer',
  "due_date": "2013-11-03T21:40:00+01:00",
  "updated_at": "2013-11-03T20:20:10+01:00",
  "created_at": "2013-11-03T20266:01+01:00"
}]
```

After this call, you will have a bunch of records in your collection.
If you want to have a direct callback, after the new records have stored, you can call the method with a block:

```ruby
Task.fetch("https://example.com/tasks") do |tasks|
  tasks.each do |task|
    puts task.name
  end
end
```

If you need specific URL parameters, you can add them as the second parameter:
```ruby
Task.fetch("https://example.com/tasks", {api_key: "top_secret!"})
```

If you want to update an existing record, you can use the instance method fetch.
```ruby
task = Task.first
task.fetch("https://example.com/tasks")
```

**Tip:** If you have the lastSyncedAt column in your model, this will automatacally set to the current timestamp!


### Saving Remote Models

If you want to store your local model, you can simply do this with MotionModelResource. You just need to configure an url class method and giving a block for the save method:

```ruby
task = Task.first
task.name = "Drinking a lot of soda"
task.save do |model|
  if model.present?
    puts "task saved!"
  else
    puts "Damn, something went wrong..."
  end
end
```

The task object will update, too. As you can see, if the model var is nil, the save process had failed.
The save method will store the relations too!! It will serialize the whole model and push this to the server. The mapping information comes also from the wrapper method.