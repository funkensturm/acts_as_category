#ActsAsCategory
[![Build Status](https://secure.travis-ci.org/mbrookes/acts_as_category.svg?branch=master)](http://travis-ci.org/mbrookes/acts_as_tree)
[![Gem Version](https://badge.fury.io/rb/acts_as_category.svg)](http://badge.fury.io/rb/acts_as_category)

      acts_as_category (Version 2.0 beta)

**acts_as_category**, is an acts_as plugin for Ruby on Rails ActiveRecord models
in the style of acts_as_tree, but with a number of additional features, and several convenient view helpers.


## Examples
(See [Usage](https://github.com/mbrookes/acts_as_category#usage) for a complete list of instance methods and view helpers.)

```ruby
class Category < ActiveRecord::Base
  acts_as_category
end

root1     = Category.create(name: 'Root 1')
child1    = Category.create(name: 'Child 1', parent_id: root1.id)
child2    = Category.create(name: 'Child 2', parent_id: root1.id)
subchild1 = Category.create(name: 'Subchild 1', parent_id: child1.id)
subchild2 = Category.create(name: 'Subchild 2', parent_id: child1.id)

root1.parent                # => nil
child1.parent               # => root1

root1.children              # => [child1, child2]
root1.children_count        # => 2

root1.descendants           # => [child1, child2, subchild1, subchild2]
root1.descendants_count     # => 4

subchild2.ancestors         # => [child1, root1]
subchild2.ancestors_count   # => 2
```

Note that unlike their `.count` equivalents, the `_count` methods are cached in the database,
so do not need to be determined through multiple database calls.


##Features

Existing solutions have various shortcomings, so acts_as_category aims to improve on those. This is what it offers:

-   It provides a structure for infinite categories and their
    subcategories (similar to acts_as_tree)
-   Each user can have his own set of category trees using the
    `:scope` feature
-   It validates that no category will be the parent of its own
    descendant and all other variations of this
-   You can define which hidden categories should still be permitted to
    the current user (through a simple class variable, thus it can
    easily be set per user)
-   There is a variety of instance methods such as `ancestors`,
    `descendants`, `descendants_ids`, `root?`, etc.
-   It has view helpers to create menus, select boxes, drag and drop
    ajax lists, etc.
-   It optionally provides sorting by a position column per hierarchy
    level, including administration methods that take parameters from
    the helpers
-   There are automatic cache columns for children, ancestors and
    descendants (good for fast menu output)
-   It is well commented and documented so that Rails beginners will
    learn from it or easily make changes
-   I18n localization for individual error messages
-   A full unit test is included
-   All options (e.g. database field names, sort order)
    configurable via a simple hash

What can acts_as_category not do?

-   You can’t easily turn off the caching
-   ActiveRecord’s “find” method won’t respect the hidden categories
    feature (but an alternative method called `get` is provided)
-   `update` and `update_attributes` must not be used to change the
    parent_id, because there is no validation callback
-   It can’t make you a coffee :)


## Requirements

-   `Rails 3.x` (note: there are currently deprecation warnings with Rails 3.2, but this does not affect functionality)


## Installation

Add `gem acts_as_category` to the Gemfile in
your Rails application.

`bundle install`

To run the **Unit Test** that comes with this plugin, please read the
instructions in `acts_as_category/test/category_test.rb`.


##Usage

###Including acts_as_category in your model

First of all you need a database table which looks something like this.
Of course you can add arbitrary fields like `name`, `description`, etc.

      class CreateCategories < ActiveRecord::Migration
        def self.up
          create_table :categories, :force => true do |t|

            # Needed by acts_as_category
            t.integer :parent_id, :children_count, :ancestors_count, :descendants_count
            t.boolean :hidden

            # Optional
            t.integer :position, :pictures_count

            # Model specific
            t.string :name, :description
          end
        end
        def self.down
          drop_table :categories
        end
      end

Next, call `acts_as_category` in the corresponding ActiveRecord model:

      class Category < ActiveRecord::Base
        acts_as_category
      end

If your database table has different column names, you can modify them.
Note that `:position` and `:order_by` are optional. Using `:order_by`
you can define any SQL ORDER BY statement. Default is `position`.

      class Category < ActiveRecord::Base
        acts_as_category :foreign_key => 'my_parent_id',
                         :hidden => 'my_hidden',
                         :children_count => 'my_children_count',
                         :ancestors_count => 'my_ancestors_count',
                         :descendants_count => 'my_descendants_count',
                         :position => 'my_position',
                         :order_by => 'title, id ASC'
      end

You can also have associations with other models. If you have a
`belongs_to` association, you must also provide a `:scope`. The scope
can be a table column or even a full SQL condition.

      class Catalogue < ActiveRecord::Base
        has_many :scoped_categories
      end

      class ScopedCategory < ActiveRecord::Base
        belongs_to :catalogue
        has_many   :pictures, :counter_cache => true
        acts_as_category :scope => :catalogue
      end

Note that it is assumed that a tree is in the same scope by any means.
I.e. `Category.root.first.children` will **not** respect the scope, but
`Category.roots.first.siblings` will (because the roots may be in
different scopes, whereas the children or a category will assumably have
the same scope).


###Including acts_as_category_content in your model

`acts_as_category` provides a function called `.permitted?` to find out
whether a category is visible according to the current user permissions.
However, you might want to have that feature for things that are
**inside** your category, say pictures or articles. That way you could
individually restrict access to these things. Just tell your content to
`acts_as_category_content` and define the corresponding model
(`category` is default if you leave it out). Like so:

      class Picture < ActiveRecord::Base
        acts_as_category_content, :category => 'my_category_model'
      end

This will also validate the associations. However, it will currently not
allow a category content to be in a category which has subcategories. It
will be optional in future versions, just uncomment the validation in
the
`vendor/plugins/acts_as_category/lib/active_record/acts/category_content.rb`
file to change this.


### Supported methods

If everything is set up, you can actually use the plugin. Let’s say you
have trees like this and your model is called **Category**.

      root1                   root2
       \_ child1               \_ child2
           \_ subchild1            \_ subchild3
           \_ subchild2            \_ subchild4

Then you can run the following methods. For more specific information
about return values, please look at the HTML documentation generated by
RDoc.

      Category.get(1)     # Returns category with id 1
      Category.get(1,5)   # Returns array of categories with ids 1 and 5

      Category.roots      # Returns an array with all permitted root categories [root1, root2]
      Category.roots!     # Same thing, but returns roots regardless of permissions (see further below)

(For the rest let’s assume that `root1 = Category.get(1)`, etc…)

      root1.root?         # Returns true, because root is a root category
      child1.root?        # Returns false

      subchild4.root      # Returns root1 because root1 is the root category
      root1.root          # Returns root1 (itself) for the same reason

      child1.parent       # Returns root
      root1.parent        # Returns nil, because root has no parent

      child1.children     # Returns an array with [subchild1, subchild2]
      child1.children_ids # Returns the same array, but ids instead of categories [3, 4]

      subchild1.ancestors       # Returns an array with [child1, root1]
      subchild1.ancestors_ids   # Returns the same array, but ids instead of categories [2, 1]
      root1.ancestors           # Returns an empty array [], because root has none

      root1.descendants         # Returns an array with [child1, subchild1, subchild2]
      root1.descendants_ids     # Returns the same array, but ids instead of categories [2, 3, 4]
      subchild1.descendants     # Returns an empty array [], because it has none

      root1.siblings                # Returns an array with all siblings [root2]
      root1.has_siblings?           # Returns true (Also .siblings? is an alias)
      root1.siblings_ids            # Returns an array with all siblings ids [5]
      child1.siblings               # Returns an empty array [], because it has no siblings

      subchild1.self_and_siblings     # Returns an array [subchild1, subchild2], just like siblings, only with itself as well
      subchild1.self_and_siblings_ids # Returns the same array, but ids instead of categories [3, 4]
      child1.self_and_siblings        # Returns an array with [child1], because it has no siblings

### Usage with permissions

Let’s bring **permissions** into the game. It let’s you show categories
for certain users, even though the categories might be flagged “hidden”.
If a category is hidden, it is practically invisible unless you have
permissions.

      child1.hidden = true
      subchild1.hidden = true

Sets child1 and subchild1 to be hidden, they are now invisible to
everyone

      root1
       \_ child1           (hidden)
           \_ subchild1    (hidden)
           \_ subchild2    (can't be found either, because child1 is hidden)

Your tree will look like this to the world:

      root1

Now we set permissions:

      Category.permissions = [2]    # i.e. [child1.id]

Say child1 has the id 2. We just allowed the current user to see it
though it’s hidden. (The idea is to set this class variable array
whenever a user logs in).

Internally this is the structure of the tree:

      root1
       \_ child1           (still hidden, but you have permissions now)
           \_ subchild1    (still hidden to you)
           \_ subchild2

If you try to access it, it will look like this:

      root1
       \_ child1
           \_ subchild2

      root1.permitted?      # Returns true, because root1 is not hidden
      child1.permitted?     # Returns true, because it's hidden but you have permissions
      subchild1.permitted?  # Returns false, because it inherits "hiddeness" by child1 and you have no explicit rights for subchild1
      subchild2.permitted?  # Returns true, because it's not hidden and you have permissions for child1

Respectively, using acts_as_content you will be able to use the same
function on a model which belongs_to a category:

      picture_of_child1.permitted?    # Returns the same thing as child1.permitted?

Note that you can still use Category.find(1) to override everything and
get any category, regardless of it’s status. So you should never use it
unless you really have to. Here is an alternative method to pick a
permitted category directly:

      child1.children     # Returns only subchild1
      Category.get(4)     # Returns an ActiveRecord::RecordNotFound error,
                            trying to access forbidden subchild2

Please have a look at the comments for each function and the unit test
to see, which method respects permissions and which ones don’t (e.g.
ancestors).


###Scopes

If you are using something, which `has_many` categories, like so:

      class ScopedCategory < ActiveRecord::Base
        belongs_to :catalog
        acts_as_category :scope => :catalog
      end

You can easily use `:scope` to let `acts_as_category` respect that.

      ScopedCategory.roots.first.siblings        # Returns the siblings, which correspond to the same @Catalogue@.

      Catalogue.first.scoped_categories.roots    # Can be used to find all visible roots for this user.

      Catalogue.first.scoped_categories.create!  # Will create a category root in the scope of that Catalogue.

You get the idea. Please notice, that it is assumed that every tree is
in one scope anyway! So `children` has nothing to do with scope, it
simply returns the children.

###Add AJAX positioning for ordering

**WARNING:** This is not tested on scopes yet! If you
`has_many :categories` you might not be able to use this.

Let’s say you have a gallery and use acts_as_category on your
categories. Then the categories will not be ordered by name (unless you
want them to), but by a individual order. For this we have the position
column. If the `:position` parameter refers to a non-existent column,
this feature is simply disabled.

You can manually update these positions, but I strongly recommend to let
this be done by the sortable_category helper and the
Category.update_positions(params) method like so:

In your layout, make sure that you have all the JavaScripts included,
that will allow drag and drop with JQuery, etc. For the
beginning, let’s just add all:

      <%= javascript_include_tag :all %>

Then, in your view, you can call this little helper to generate a drag
and drop list where you can re-sort the positions. Remember to provide
the name of the model to use:

      <%= aac_sortable_tree Category %>

Finally, in your controller create an action method like this:

      def update_positions
        Category.update_positions(params)
        render :nothing => true
      end

And you can already try it. You can change the URL to that action method
like this:

      <%= aac_sortable_tree(Category, {action: :update_positions}) %>
      <%= aac_sortable_tree(Category, {controller: :mycontroller, action: :update_positions}) %>


##FAQ

**Why is `find` not respecting hidden?**

I didn’t feel comfortable overwriting the find method for Categories and
it is not really needed (use `get` instead).

**Why are `ancestors`, `ancestors_ids` and `self.parent` not respecting
hidden/permissions?**

Because the whole idea of hidden is to exclude descendants of an hidden
Category as well, thus the ancestors of a category you can access anyway
are never going to be hidden.


## Contributing

Pull requests welcome!


## License

Copyright 2014
<a href="http://www.funkensturm.com">www.funkensturm.com</a>, released
under the *MIT/X11 license*, which is free for all to do whatever you
want with it.
