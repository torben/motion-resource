MotionResource: Simple JSON API Wrapper for MotionModel on RubyMotion
================

MotionResource is a simple wrapper to store your remote data in MotionModel objects. It is good for users who have a
REST API and want to have it in an iOS app.

You need to have MotionModel ready, if you want to use this implementation: https://github.com/sxross/MotionModel


### Overview
* [Setup](#setup)
* [Usage](#usage)


Setup
================

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
  include MotionResource::ApiWrapper

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
================

### Getting Remote Models

Fetching your API by calling "fetch" on your model class:

```ruby
Task.fetch("https://example.com/tasks")
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

Tip: If you have the lastSyncedAt column in your model, this will automatacally set to the current timestamp!


### Saving Remote Models

If you want to store your local model, you can simply do this with MotionResource. You just need to configure an url class method and giving a block for the save method:

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