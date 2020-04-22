# Models relationships
* `Author` has many `Computer`s
* `Author` has many `Post`s
* `Post` has many `Comment`s

# Problem
A `has_many :comments` association retrieves duplicate records.
If we preload `author: :posts`, and then preload `:comments` on `posts` obtained via : `posts = computers.map(&:author).flat_map(&:posts)`, `comments` association on `posts.first` record will return duplicate instances of the comment (see Trigger the problem section for details).
In this example, we do not have any valid reason to this : we could just `preload(author: [posts: [:comments]])` and things would work just fine. However, when dealing with polymorphic associations, we sometime want to `select` a certain type of records before preloading the sub-association records onto-it. 

# Steps to reproduce

## Seed database
`development.sqlite3` should already contain what's necessary to trigger the problem. If you want to recreate database and seed it with what's necessary to trigger the problem, you can proceed as below.
* `rails db:drop db:create db:migrate`
* `rails console`
Type in :
```ruby
irb(main):001:0> author = Author.create(name: 'Toto')
=> #<Author id: 1, name: "Toto", created_at: "2020-04-22 16:51:37", updated_at: "2020-04-22 16:51:37">
irb(main):002:0> 3.times { Computer.create(author: author) }
=> 3
irb(main):003:0> post = Post.create(author: author)
=> #<Post id: 1, title: nil, created_at: "2020-04-22 16:52:44", updated_at: "2020-04-22 16:52:44", author_id: 1>
irb(main):004:0> Comment.create(post: post)
=> #<Comment id: 1, post_id: 1, content: nil, created_at: "2020-04-22 16:52:54", updated_at: "2020-04-22 16:52:54">
```

## Trigger the problem
```ruby
irb(main):005:0> computers = Computer.all.preload(author: :posts)
=> #<ActiveRecord::Relation [#<Computer id: 1, author_id: 1, created_at: "2020-04-22 16:52:24", updated_at: "2020-04-22 16:52:24">, #<Computer id: 2, author_id: 1, created_at: "2020-04-22 16:52:24", updated_at: "2020-04-22 16:52:24">, #<Computer id: 3, author_id: 1, created_at: "2020-04-22 16:52:24", updated_at: "2020-04-22 16:52:24">]>
irb(main):006:0> posts = computers.map(&:author).flat_map(&:posts)
=> [#<Post id: 1, title: nil, created_at: "2020-04-22 16:52:44", updated_at: "2020-04-22 16:52:44", author_id: 1>, #<Post id: 1, title: nil, created_at: "2020-04-22 16:52:44", updated_at: "2020-04-22 16:52:44", author_id: 1>, #<Post id: 1, title: nil, created_at: "2020-04-22 16:52:44", updated_at: "2020-04-22 16:52:44", author_id: 1>]
irb(main):007:0> ActiveRecord::Associations::Preloader.new.preload(posts, :comments)
=> [#<ActiveRecord::Associations::Preloader::Association:0x00007fd8b84ad5b0 @klass=Comment(id: integer, post_id: integer, content: string, created_at: datetime, updated_at: datetime), @owners=[#<Post id: 1, title: nil, created_at: "2020-04-22 16:52:44", updated_at: "2020-04-22 16:52:44", author_id: 1>, #<Post id: 1, title: nil, created_at: "2020-04-22 16:52:44", updated_at: "2020-04-22 16:52:44", author_id: 1>, #<Post id: 1, title: nil, created_at: "2020-04-22 16:52:44", updated_at: "2020-04-22 16:52:44", author_id: 1>], @reflection=#<ActiveRecord::Reflection::HasManyReflection:0x00007fd8c85e7e48 @name=:comments, @scope=nil, @options={}, @active_record=Post(id: integer, title: string, created_at: datetime, updated_at: datetime, author_id: integer), @klass=Comment(id: integer, post_id: integer, content: string, created_at: datetime, updated_at: datetime), @plural_name="comments", @type=nil, @foreign_type=nil, @constructable=true, @association_scope_cache=#<Concurrent::Map:0x00007fd8c85e78f8 entries=0 default_proc=nil>, @class_name="Comment", @inverse_name=:post, @inverse_of=#<ActiveRecord::Reflection::BelongsToReflection:0x00007fd8c86f7dd8 @name=:post, @scope=nil, @options={}, @active_record=Comment(id: integer, post_id: integer, content: string, created_at: datetime, updated_at: datetime), @klass=Post(id: integer, title: string, created_at: datetime, updated_at: datetime, author_id: integer), @plural_name="posts", @type=nil, @foreign_type=nil, @constructable=true, @association_scope_cache=#<Concurrent::Map:0x00007fd8c86f7ab8 entries=0 default_proc=nil>, @class_name="Post", @inverse_name=nil, @foreign_key="post_id">, @active_record_primary_key="id", @foreign_key="post_id">, @preload_scope=nil, @model=Post(id: integer, title: string, created_at: datetime, updated_at: datetime, author_id: integer), @key_conversion_required=false, @owners_by_key={1=>[#<Post id: 1, title: nil, created_at: "2020-04-22 16:52:44", updated_at: "2020-04-22 16:52:44", author_id: 1>, #<Post id: 1, title: nil, created_at: "2020-04-22 16:52:44", updated_at: "2020-04-22 16:52:44", author_id: 1>, #<Post id: 1, title: nil, created_at: "2020-04-22 16:52:44", updated_at: "2020-04-22 16:52:44", author_id: 1>]}, @owner_keys=[1], @scope=#<ActiveRecord::Relation [#<Comment id: 1, post_id: 1, content: nil, created_at: "2020-04-22 16:52:54", updated_at: "2020-04-22 16:52:54">]>, @preloaded_records=#<ActiveRecord::Relation [#<Comment id: 1, post_id: 1, content: nil, created_at: "2020-04-22 16:52:54", updated_at: "2020-04-22 16:52:54">]>, @records_by_owner={#<Post id: 1, title: nil, created_at: "2020-04-22 16:52:44", updated_at: "2020-04-22 16:52:44", author_id: 1>=>[#<Comment id: 1, post_id: 1, content: nil, created_at: "2020-04-22 16:52:54", updated_at: "2020-04-22 16:52:54">, #<Comment id: 1, post_id: 1, content: nil, created_at: "2020-04-22 16:52:54", updated_at: "2020-04-22 16:52:54">, #<Comment id: 1, post_id: 1, content: nil, created_at: "2020-04-22 16:52:54", updated_at: "2020-04-22 16:52:54">]}>]
irb(main):008:0> posts.first.comments
=> #<ActiveRecord::Associations::CollectionProxy [#<Comment id: 1, post_id: 1, content: nil, created_at: "2020-04-22 16:52:54", updated_at: "2020-04-22 16:52:54">, #<Comment id: 1, post_id: 1, content: nil, created_at: "2020-04-22 16:52:54", updated_at: "2020-04-22 16:52:54">, #<Comment id: 1, post_id: 1, content: nil, created_at: "2020-04-22 16:52:54", updated_at: "2020-04-22 16:52:54">]>
irb(main):009:0>
```
We can see that `posts.first.comments` returns multiple times the `Comment` with `id: 1`.