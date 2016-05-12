defmodule Ecto do
  @moduledoc ~S"""
  Ecto is split into 4 main components:

    * `Ecto.Repo` - repositories are wrappers around the database.
      Via the repository, we can create, update, destroy and query existing entries.
      A repository needs an adapter and a URL to communicate to the database

    * `Ecto.Schema` - schemas allow developers to define data structures
      that map to the underlying storage

    * `Ecto.Changeset` - changesets provide a way for developers to filter
      and cast external parameters, as well as a mechanism to track and
      validate changes before their are sent to the database

    * `Ecto.Query` - written in Elixir syntax, queries are used to retrieve
      information from a given repository. Queries in Ecto are secure, avoiding
      common problems like SQL Injection, and also provide type safety. Queries
      are composable via the `Ecto.Queryable` protocol

  In the following sections, we will provide an overview of those components and
  how they interact with each other. Feel free to access their respective module
  documentation for more specific examples, options and configuration.

  If you want to quickly check a sample application using Ecto, please check
  https://github.com/elixir-lang/ecto/tree/master/examples/simple.

  ## Repositories

  `Ecto.Repo` is a wrapper around the database. We can define a
  repository as follows:

      defmodule Repo do
        use Ecto.Repo, otp_app: :my_app
      end

  Where the configuration for the Repo must be in your application
  environment, usually defined in your `config/config.exs`:

      config :my_app, Repo,
        adapter: Ecto.Adapters.Postgres,
        database: "ecto_simple",
        username: "postgres",
        password: "postgres",
        hostname: "localhost"

  Each repository in Ecto defines a `start_link/0` function that needs to be invoked
  before using the repository. In general, this function is not called directly,
  but used as part of your application supervision tree.

  If your application was generated with a supervisor (by passing `--sup` to `mix new`)
  you will have a `lib/my_app.ex` file containing the application start callback that
  defines and starts your supervisor. You just need to edit the `start/2` function to
  start the repo as a supervisor on your application's supervisor:

      def start(_type, _args) do
        import Supervisor.Spec

        children = [
          supervisor(Repo, [])
        ]

        opts = [strategy: :one_for_one, name: MyApp.Supervisor]
        Supervisor.start_link(children, opts)
      end

  ## Schema

  Schema provide a set of functionalities around structuring your data,
  defining relationships and applying changes to repositories.

  Let's see an example:

      defmodule Weather do
        use Ecto.Schema

        # weather is the DB table
        schema "weather" do
          field :city,    :string
          field :temp_lo, :integer
          field :temp_hi, :integer
          field :prcp,    :float, default: 0.0
        end
      end

  By defining a schema, Ecto automatically defines a struct with
  the schema fields:

      iex> weather = %Weather{temp_lo: 30}
      iex> weather.temp_lo
      30

  The schema also allows us to interact with a repository:

      iex> weather = %Weather{temp_lo: 0, temp_hi: 23}
      iex> Repo.insert!(weather)
      %Weather{...}

  After persisting `weather` to the database, it will return a new copy of
  `%Weather{}` with the primary key (the `id`) set. We can use this value
  to read a struct back from the repository:

      # Get the struct back
      iex> weather = Repo.get Weather, 1
      %Weather{id: 1, ...}

      # Delete it
      iex> Repo.delete!(weather)
      %Weather{...}

  > NOTE: by using `Ecto.Schema`, an `:id` field with type `:integer` is
  > generated by default, which is the primary key of the Model. If you want
  > to use a different primary key, you can declare custom `@primary_key`
  > before the `schema/2` call. Consult the `Ecto.Schema` documentation
  > for more information.

  Notice how the storage (repository) and the data are decoupled. This provides
  two main benefits:

    * By having structs as data, we guarantee they are light-weight,
      serializable structures. In many languages, the data is often represented
      by large, complex objects, with entwined state transactions, which makes
      serialization, maintenance and understanding hard;

    * By making the storage explicit with repositories, we don't pollute the
      repository with unnecessary overhead, providing straight-forward and
      performant access to storage;

  ## Changesets

  Although in the example above we have directly inserted and deleted the
  struct in the repository, update operations must be done through changesets
  so Ecto can efficiently track changes.

  Further than that, changesets allow developers to filter, cast, and validate
  changes before we apply them to the data. Imagine the given schema:

      defmodule User do
        use Ecto.Schema

        import Ecto.Changeset

        schema "users" do
          field :name
          field :email
          field :age, :integer
        end

        def changeset(user, params \\ :empty) do
          user
          |> cast(params, ~w(name email), ~w(age))
          |> validate_format(:email, ~r/@/)
          |> validate_inclusion(:age, 18..100)
        end
      end

  The `changeset/2` function first invokes `Ecto.Changeset.cast/4` with
  the struct, the parameters and a list of required and optional fields;
  this returns a changeset. The parameter is a map with binary keys and
  a value that will be cast based on the type defined on the schema.

  Any parameter that was not explicitly listed in the required or
  optional fields list will be ignored. Furthermore, if a field is given
  as required but it is not in the parameter map nor in the struct,
  it will be marked with an error and the changeset is deemed invalid.

  After casting, the changeset is given to many `Ecto.Changeset.validate_*/2`
  functions that validate only the **changed fields**. In other words:
  if a field was not given as a parameter, it won't be validated at all.
  For example, if the params map contain only the "name" and "email" keys,
  the "age" validation won't run.

  As an example, let's see how we could use the changeset above in
  a web application that needs to update users:

      def update(id, params) do
        changeset = User.changeset Repo.get!(User, id), params["user"]

        case Repo.update(changeset) do
          {:ok, user} ->
            send_resp conn, 200, "Ok"
          {:error, changeset} ->
            send_resp conn, 400, "Bad request"
        end
      end

  The `changeset/2` function receives the user and its parameters
  and returns a changeset. If the changeset is valid, we persist the
  changes to the database, otherwise, we handle the error by emitting
  a bad request code.

  Another example to create users:

      def create(id, params) do
        changeset = User.changeset %User{}, params["user"]

        case Repo.insert(changeset) do
          {:ok, user} ->
            send_resp conn, 200, "Ok"
          {:error, changeset} ->
            send_resp conn, 400, "Bad request"
        end
      end

  The benefit of having explicit changesets is that we can easily provide
  different changesets for different use cases. For example, one
  could easily provide specific changesets for create and update:

      def create_changeset(user, params) do
        # Changeset on create
      end

      def update_changeset(user, params) do
        # Changeset on update
      end

  Changesets are also capable of transforming database constraints,
  like unique indexes and foreign key checks, into errors. Allowing
  developers to keep their database consistent while still providing
  proper feedback to end users. Check `Ecto.Changeset.unique_constraint/3`
  for some examples as well as the other `_constraint` functions.

  ## Query

  Last but not least, Ecto allows you to write queries in Elixir and send
  them to the repository, which translates them to the underlying database.
  Let's see an example:

      import Ecto.Query, only: [from: 2]

      query = from w in Weather,
            where: w.prcp > 0 or is_nil(w.prcp),
           select: w

      # Returns %Weather{} structs matching the query
      Repo.all(query)

  Queries are defined and extended with the `from` macro. The supported
  keywords are:

    * `:distinct`
    * `:where`
    * `:order_by`
    * `:offset`
    * `:limit`
    * `:lock`
    * `:group_by`
    * `:having`
    * `:join`
    * `:select`
    * `:preload`

  Examples and detailed documentation for each of those are available
  in the `Ecto.Query` module. Functions supported in queries are listed
  in `Ecto.Query.API`.

  When writing a query, you are inside Ecto's query syntax. In order to
  access params values or invoke Elixir functions, you need to use the `^`
  operator, which is overloaded by Ecto:

      def min_prcp(min) do
        from w in Weather, where: w.prcp > ^min or is_nil(w.prcp)
      end

  Besides `Repo.all/1`, which returns all entries, repositories also
  provide `Repo.one/1`, which returns one entry or nil, and `Repo.one!/1`
  which returns one entry or raises.

  ## Other topics

  ### Associations

  Ecto supports defining associations on schemas:

      defmodule Post do
        use Ecto.Schema

        schema "posts" do
          has_many :comments, Comment
        end
      end

      defmodule Comment do
        use Ecto.Schema

        schema "comments" do
          field :title, :string
          belongs_to :post, Post
        end
      end

  When an association is defined, Ecto also defines a field in the schema
  with the association name. By default, associations are not loaded into
  this field:

      iex> post = Repo.get(Post, 42)
      iex> post.comments
      #Ecto.Association.NotLoaded<...>

  However, developers can use the preload functionality in queries to
  automatically pre-populate the field:

      Repo.all from p in Post, preload: [:comments]

  Preloading can also be done with a pre-defined join value:

      Repo.all from p in Post,
                join: c in assoc(p, :comments),
                where: c.votes > p.votes,
                preload: [comments: c]

  Finally, for the simple cases, preloading can also be done after
  a collection was fetched:

      posts = Repo.all(Post) |> Repo.preload(:comments)

  The `Ecto.Model` module also provides conveniences for working
  with associations. For example, `Ecto.assoc/2` returns a query
  with all associated data to a given struct:

      import Ecto

      # Get all comments for the given post
      Repo.all assoc(post, :comments)

      # Or build a query on top of the associated comments
      query = from c in assoc(post, :comments), where: c.title != nil
      Repo.all(query)

  Another function in `Ecto` is `build_assoc/3`, which allows
  someone to build an associated struct with the proper fields:

      Repo.transaction fn ->
        post = Repo.insert!(%Post{title: "Hello", body: "world"})

        # Build a comment from post
        comment = Ecto.build_assoc(post, :comments, body: "Excellent!")

        Repo.insert!(comment)
      end

  In the example above, `Ecto.build_assoc/3` is equivalent to:

      %Comment{post_id: post.id, body: "Excellent!"}

  You can find more information about defining associations and each
  respective association module in `Ecto.Schema` docs.

  > NOTE: Ecto does not lazy load associations. While lazily loading
  > associations may sound convenient at first, in the long run it
  > becomes a source of confusion and performance issues.

  ### Embeds

  Ecto also supports embeds. While associations keep parent and child
  entries in different tables, embeds stores the child along side the
  parent.

  Databases like Mongo have native support for embeds. Databases
  like PostgreSQL uses a mixture of JSONB (`embeds_one/3`) and ARRAY
  columns to provide this functionality.

  Check `Ecto.Schema.embeds_one/3` and `Ecto.Schema.embeds_many/3`
  for more information.

  ### Mix tasks and generators

  Ecto provides many tasks to help your workflow as well as code generators.
  You can find all available tasks by typing `mix help` inside a project
  with Ecto listed as a dependency.

  Ecto generators will automatically open the generated files if you have
  `ECTO_EDITOR` set in your environment variable.

  #### Migrations

  Ecto supports database migrations. You can generate a migration with:

      $ mix ecto.gen.migration create_posts

  This will create a new file inside `priv/repo/migrations` with the `up` and
  `down` functions. Check `Ecto.Migration` for more information.

  #### Repo resolution

  Our of the box, Ecto tasks assumes that the location of your Repo lives within
  your application's root namespace; for example, in the previous examples, Ecto
  will assume your Repo is located at MyApp.Repo.

  For more complex use-cases, this might not be sufficient and Ecto allows you
  to provide an alternative namespace or Repo location using the `app_namespace`
  or the `app_repo` configuration variables as follows:

      config :my_app, :app_repo, My.App.Repo
      config :my_app, My.App.Repo,
        adapter: Ecto.Adapters.Postgres,
        database: "ecto_simple",
        username: "postgres",
        password: "postgres",
        hostname: "localhost"

  In this example the configuration `:app_repo` is used to explicitly provide
  the default Repo to use. Alternatively, the `:app_namespace` config could
  have been set to `My.App` to achieve the same result.
  """

  @doc """
  Returns the schema primary keys as a keyword list.
  """
  @spec primary_key(Ecto.Schema.t) :: Keyword.t
  def primary_key(%{__struct__: module} = struct) do
    Enum.map module.__schema__(:primary_key), fn(field) ->
      {field, Map.fetch!(struct, field)}
    end
  end

  @doc """
  Returns the schema primary keys as a keyword list.

  Raises `Ecto.NoPrimaryKeyFieldError` if the model has no
  primary key field.
  """
  @spec primary_key!(Ecto.Schema.t) :: Keyword.t | no_return
  def primary_key!(struct) do
    case primary_key(struct) do
      [] -> raise Ecto.NoPrimaryKeyFieldError, model: struct
      pk -> pk
    end
  end

  @doc """
  Builds a struct from the given `assoc` in `model`.

  ## Examples

  If the relationship is a `has_one` or `has_many` and
  the key is set in the given model, the key will automatically
  be set in the built association:

      iex> post = Repo.get(Post, 13)
      %Post{id: 13}
      iex> build_assoc(post, :comments)
      %Comment{id: nil, post_id: 13}

  Note though it doesn't happen with belongs to cases, as the
  key is often the primary key and such is usually generated
  dynamically:

      iex> comment = Repo.get(Comment, 13)
      %Comment{id: 13, post_id: 25}
      iex> build_assoc(comment, :post)
      %Post{id: nil}

  You can also pass the attributes, which can be a map or
  a keyword list, to set the struct's fields except the
  association key.

      iex> build_assoc(post, :comments, text: "cool")
      %Comment{id: nil, post_id: 13, text: "cool"}

      iex> build_assoc(post, :comments, %{text: "cool"})
      %Comment{id: nil, post_id: 13, text: "cool"}

      iex> build_assoc(post, :comments, post_id: 1)
      %Comment{id: nil, post_id: 13}
  """
  def build_assoc(%{__struct__: model} = struct, assoc, attributes \\ %{}) do
    assoc = Ecto.Association.association_from_model!(model, assoc)
    assoc.__struct__.build(assoc, struct, Dict.delete(attributes, :__meta__))
  end

  @doc """
  Builds a query for the association in the given model or models.

  ## Examples

  In the example below, we get all comments associated to the given
  post:

      post = Repo.get Post, 1
      Repo.all assoc(post, :comments)

  `assoc/2` can also receive a list of posts, as long as the posts are
  not empty:

      posts = Repo.all from p in Post, where: is_nil(p.published_at)
      Repo.all assoc(posts, :comments)

  """
  def assoc(model_or_models, assoc) do
    structs = List.wrap(model_or_models)

    if structs == [] do
      raise ArgumentError, "cannot retrieve association #{inspect assoc} for empty list"
    end

    model = hd(structs).__struct__
    assoc = %{owner_key: owner_key} =
      Ecto.Association.association_from_model!(model, assoc)

    values =
      Enum.uniq for(struct <- structs,
        assert_struct!(model, struct),
        key = Map.fetch!(struct, owner_key),
        do: key)

    assoc.__struct__.assoc_query(assoc, values)
  end

  @doc """
  Checks if an association is loaded.

  ## Examples

      iex> post = Repo.get(Post, 1)
      iex> Ecto.assoc_loaded?(post.comments)
      false
      iex> post = post |> Repo.preload(:comments)
      iex> Ecto.assoc_loaded?(post.comments)
      true

  """
  def assoc_loaded?(association) do
    case association do
      %Ecto.Association.NotLoaded{} -> false
      _ -> true
    end
  end

  @doc """
  Updates the model metadata.

  It is possible to set:

    * `:source` - changes the model query source
    * `:prefix` - changes the model query prefix
    * `:context` - changes the model meta context
    * `:state` - changes the model state
  """
  @spec put_meta(Ecto.Schema.t, [source: String.t, prefix: String.t,
                                context: term, state: :built | :loaded | :deleted]) :: Ecto.Schema.t
  def put_meta(model, opts) do
    update_in model.__meta__, &update_meta(opts, &1)
  end

  defp update_meta([{:state, state}|t], meta) do
    if state in [:built, :loaded, :deleted] do
      update_meta t, %{meta | state: state}
    else
      raise ArgumentError, "invalid state #{inspect state}"
    end
  end

  defp update_meta([{:source, source}|t], %{source: {prefix, _}} = meta) do
    update_meta t, %{meta | source: {prefix, source}}
  end

  defp update_meta([{:prefix, prefix}|t], %{source: {_, source}} = meta) do
    update_meta t, %{meta | source: {prefix, source}}
  end

  defp update_meta([{:context, context}|t], meta) do
    update_meta t, %{meta | context: context}
  end

  defp update_meta([], meta) do
    meta
  end

  defp update_meta([{k, _}], _meta) do
    raise ArgumentError, "unknown meta key #{inspect k}"
  end

  defp assert_struct!(model, %{__struct__: struct}) do
    if struct != model do
      raise ArgumentError, "expected a homogeneous list containing the same struct, " <>
                           "got: #{inspect model} and #{inspect struct}"
    else
      true
    end
  end
end