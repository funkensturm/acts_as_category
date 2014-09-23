Introduction
============

      acts_as_category (Version 2.0 beta)

Let me explain to you what I mean by **acts\_as\_category**, which is
yet another acts\_as plugin for Ruby on Rails ActiveRecord models.
Copyright is 2014 by
<a href="http://www.funkensturm.com">www.funkensturm.com</a>, released
under the *MIT/X11 license*, which is free for all to do whatever you
want with it.

### acts\_as\_tree provides functionality for trees, but lacks some things:

-   It has no descendants method or things like `ancestors_ids`
-   It doesn’t validate `parent_id` whatsoever, which means that you can
    make a category a parent of itself, etc.
-   It has no caching for ancestors and descendants (you need that to
    output trees using `<ul>` and `<li>` efficiently)
-   It won’t help if you want certain users to see only certain nodes
-   There is no scoping, thus `root.siblings` will return **all** roots,
    instead of this users’ roots only.

### acts\_as\_list is maybe not exactly what I want either:

-   It also has no validation or features to hide particular entries
-   It doesn’t support a script.aculo.us sortable\_list to reorder the
    tree
-   It has more than you might need, providing all these
    *move\_just\_a\_little\_bit\_higher* methods
-   Last but not least, it won’t work together with *acts\_as\_tree*
    unless you hack around a lot with the scope code

### So I came up with acts\_as\_category, and this is what it does:

-   It provides a structure for infinite categories and their
    subcategories (similar to acts\_as\_tree)
-   Each user can have his own set of category trees using the
    `:scope` feature
-   It validates that no category will be the parent of its own
    descendant and all other variations of these foreign key things
-   You can define which hidden categories should still be permitted to
    the current user (through a simple class variable, thus it can
    easily be set per user)
-   There is a variety of instance methods such as `ancestors`,
    `descendants`, `descendants_ids`, `root?`, etc.
-   It has view helpers to create menus, select boxes, drag and drop
    ajax lists, etc. (they need refactorization, though)
-   It optionally provides sorting by a position column per hierarchy
    level, including administration methods that take parameters from
    the helpers
-   There are automatic cache columns for children, ancestors and
    descendants (good for fast menu output)
-   It is well commented and documented so that Rails beginners will
    learn from it or easily make changes
-   I18n localization for individual error messages
-   A full unit test comes along with it
-   As you can see in the test: All options (e.g. database field names)
    highly configurable via a simple hash

### What can acts\_as\_category NOT do?

-   You can’t simply “turn off” the caching feature to speed up your
    application. If you really want to make this thing more efficient
    than it already is, `memoize` each critical function (it work’s
    fine, since I’m using it myself, but the unit tests will fail
    whenever I use memoize, that’s why it’s not published. Update: maybe
    I should double-check this again, maybe it works by now).
-   ActiveRecord’s “find” method won’t respect the hidden categories
    feature (but a somewhat alternative method called `get` is provided)
-   `update` and `update_attributes` must not be used to change the
    parent\_id, because there is no validation callback
-   It can’t make you a coffee

### Demonstration

Find a out-of-the-box demo application at
<a href="http://github.com/funkensturm/funkengallery_demo">www.github.com/funkensturm/funkengallery\_demo</a>
(note that this demo is using version `1.0`, but you get the idea).

### Requirements

-   `Rails 2.3.5` or higher (maybe lower, as well :)

### Installation

Just copy the **acts\_as\_category** directory into `vendor/plugins` in
your Rails application.

To generate **HTML documentation** for all your plugins, run
`rake doc:plugins`.\
To generate it just for this plugin, go to
`vendor/plugins/acts_as_category` and run `rake rdoc`.

To run the **Unit Test** that comes with this plugin, please read the
instructions in `vendor/plugins/acts_as_category/test/category_test.rb`.

Documentation
=============

Including acts\_as\_category in your model
------------------------------------------

First of all you need a database table which looks something like this.
Of course you can add arbitrary fields like `name`, `description`, etc.

      class CreateCategories < ActiveRecord::Migration
        def self.up
          create_table :categories, :force => true do |t|

            # Needed by acts_as_category
            t.integer :parent_id, :children_count, :ancestors_count, :descendants_count
            t.boolean :hidden

            # Optional
            t.string :name, :description
            t.integer :position, :pictures_count

          end
        end
        def self.down
          drop_table :categories
        end
      end

Notice that the mandatory table names above are needed by default (i.e.
`parent_id`, `children_count`, `ancestors_count`, `descendants_count`,
`hidden`). To make it work, you need to call `acts_as_category` in the
corresponding ActiveRecord model:

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

Including acts\_as\_category\_content in your model
---------------------------------------------------

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

Tutorial
--------

If everything is set up, you can actually use the plugin. Let’s say you
have trees like this and your model is called **Category**.

      root1                   root2
       \_ child1               \_ child2
            \_ subchild1            \subchild3
            \_ subchild2                \subchild4

Then you can run the following methods. For more specific information
about return values, please look at the HTML documentation generated by
RDoc.

      Category.get(1)     # Returns category with id 1
      Category.get(1,5)   # Returns array of categories with ids 1 and 5

     Category.roots       # Returns an array with all permitted root categories [root1, root2]
     Category.roots!      # Same thing, but returns roots regardless of permissions (see further below)

(For the rest let’s assume, that root1 = Category.get(1), etc…)

      root1.root?         # Returns true, because root is a root category
      child1.root?        # Returns false

      child1.parent       # Returns root
      root.parent         # Returns nil, because root has no parent

      root.children       # Returns an array with [subchild1, subchild2].

      subchild1.ancestors       # Returns an array with [child1, root1]
      subchild1.ancestors_ids   # Returns the same array, but ids instead of categories [2,1]
      root1.ancestors           # Returns an empty array [], because root has none

      root1.descendants         # Returns an array with [child1, subchild1, subchild2]
      root1.descendants_ids     # Returns the same array, but ids instead of categories [2,3,4]
      subchild1.descendants     # Returns an empty array [], because it has none

      root1.siblings                # Returns an array with all siblings [root2]
      child1.siblings               # Returns an empty array [], because it has no siblings
      subchild1.self_and_siblings   # Returns an array [subchild1, subchild2], just like siblings, only with itself as well

Usage with permissions
----------------------

Let’s bring **permissions** into the game. It let’s you show categories
for certain users, even though the categories might be flagged “hidden”.
If a category is hidden, it is practically invisible unless you have
permissions.

      child1.hidden = true
      subchild1.hidden = true

Sets child1 and subchild1 to be hidden, they are now invisible to
everyone

      root1
       \_ child1             (hidden)
            \_ subchild1     (hidden)
            \_ subchild2     (can't be found either, because child1 is hidden)

Your tree will look like this to the world:

      root1

Now we set permissions:

      Category.permissions = [2]    # i.e. [child1.id]

Say child1 has the id 2. We just allowed the current user to see it
though it’s hidden. (The idea is to set this class variable array
whenever a user logs in).

Internally this is the structure of the tree:

      root1
       \_ child1            (still hidden, but you have permissions now)
            \_ subchild1    (still hidden to you)
            \_ subchild2

If you try to access it, it will look like this:

      root1
       \_ child1
            \_ subchild2

      root1.permitted?      # Returns true, because root1 is not hidden
      child1.permitted?     # Returns true, because it's hidden but you have permissions
      subchild1.permitted?  # Returns false, because it inherits "hiddenness" by child1 and you have no explicit rights for subchild1
      subchild2.permitted?  # Returns true, because it's not hidden and you have permissions for child1

Respectively, using acts\_as\_content you will be able to use the same
function on a model which belongs\_to a category:

      picture_of_child1.permitted?    # Returns the same thing as child1.permitted?

Note that you can still use Category.find(1) to override everything and
get any category, regardless of it’s status. So you should never use it
unless you really have to. Here is an alternative method to pick a
permitted category directly:

      child1.children     # Returns only subchild1
      Category.get(4)     # Returns an empty array, trying to access forbidden subchild2

Please have a look at the comments for each function and the unit test
to see, which method respects permissions and which one doesn’t (e.g.
ancestors).

Scopes
------

If you are using something, which `has_many` categories, like so:

      class ScopedCategory < ActiveRecord::Base
        belongs_to :catalogue
        acts_as_category :scope => :catalogue
      end

You can easily use `:scope` to let `acts_as_category` respect that.

      ScopedCategory.roots.first.siblings        # Returns the siblings, which correspond to the same @Catalogue@.

      Catalogue.first.scoped_categories.roots    # Can be used to find all visible roots for this user.

      Catalogue.first.scoped_categories.create!  # Will create a category root in the scope of that Catalogue.

You get the idea. Please notice, that it is assumed that every tree is
in one scope anyway! So `children` has nothing to do with scope, it
simply returns the children.

FAQ
---

**Why is *find* not respecting hidden?**

I didn’t feel comfortable overwriting the find method for Categories and
it is not really needed.

**Why are `ancestors`, `ancestors_ids` and `self.parent` not respecting
hidden/permissions?**

Because the whole idea of hidden is to exclude descendants of an hidden
Category as well, thus the ancestors of a category you can access anyway
are never going to be hidden.

Add AJAX positioning for ordering
---------------------------------

**WARNING:** This is not tested on scopes yet! If you
`has_many :categories` you might not be able to use this.

Let’s say you have a gallery and use acts\_as\_category on your
categories. Then the categories will not be ordered by name (unless you
want them to), but by a individual order. For this we have the position
column. If the `:position` parameter refers to a non-existent column,
this feature is simply disabled.

You can manually update these positions, but I strongly recommend to let
this be done by the sortable\_category helper and the
Category.update\_positions(params) method like so:

In your layout, make sure that you have all the JavaScripts included,
that will allow drag and drop with script.aculo.us, etc. For the
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

      <%= aac_sortable_tree(Category, {:action => :update_positions}) %>
      <%= aac_sortable_tree(Category, {:controller => :mycontroller, :action => :update_positions}) %>

Ask questions and have fun!
---------------------------

Feel free to add your comments and don’t forget about the
<a href="http://github.com/funkensturm/funkengallery_demo">demo
application</a>.


# ActsAsCategory

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'acts_as_category'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install acts_as_category

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/[my-github-username]/acts_as_category/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
