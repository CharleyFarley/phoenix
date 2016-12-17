defmodule Mix.Tasks.Phx.New.Web do
  use Mix.Task
  use Phx.New.Generator
  alias Mix.Tasks.Phx.New.{App}
  alias Phx.New.{Project}

  @pre "phx_umbrella/apps/app_name_web"

  # TODO
  #
  # Umbrella => only base proj mix.exs and apps/, then delegates
  # gen_ecto and gen_web to phx.web and phx.ecto
  #
  # extract Umbrella web generation to Web task
  # extract Umbrella ecto generation to Ecto task
  #
  #

  template :new, [
    {:eex,  "#{@pre}/config/config.exs",      :web, "config/config.exs"},
    {:eex,  "#{@pre}/config/dev.exs",         :web, "config/dev.exs"},
    {:eex,  "#{@pre}/config/prod.exs",        :web, "config/prod.exs"},
    {:eex,  "#{@pre}/config/prod.secret.exs", :web, "config/prod.secret.exs"},
    {:eex,  "#{@pre}/config/test.exs",        :web, "config/test.exs"},
    {:eex,  "#{@pre}/test/test_helper.exs",   :web, "test/test_helper.exs"},
    {:eex,  "#{@pre}/lib/application.ex",     :web, "lib/application.ex"},
    {:eex,  "#{@pre}/lib/web.ex",             :web, "lib/web.ex"},
    {:eex,  "#{@pre}/lib/endpoint.ex",        :web, "lib/endpoint.ex"},
    {:eex,  "#{@pre}/lib/gettext.ex",         :web, "lib/gettext.ex"},
    {:eex,  "#{@pre}/lib/router.ex",          :web, "lib/router.ex"},
    {:eex,  "#{@pre}/README.md",              :web, "README.md"},
    {:eex,  "#{@pre}/mix.exs",                :web, "mix.exs"},
    {:keep, "#{@pre}/test/channels",                  :web, "test/channels"},
    {:keep, "#{@pre}/test/controllers",               :web, "test/controllers"},
    {:eex,  "#{@pre}/test/views/error_view_test.exs", :web, "test/views/error_view_test.exs"},
    {:eex,  "#{@pre}/test/support/conn_case.ex",      :web, "test/support/conn_case.ex"},
    {:eex,  "#{@pre}/test/support/channel_case.ex",   :web, "test/support/channel_case.ex"},
    {:eex,  "#{@pre}/lib/channels/user_socket.ex",    :web, "lib/channels/user_socket.ex"},
    {:keep, "#{@pre}/lib/controllers",                :web, "lib/controllers"},
    {:eex,  "#{@pre}/lib/views/error_view.ex",        :web, "lib/views/error_view.ex"},
    {:eex,  "#{@pre}/lib/views/error_helpers.ex",     :web, "lib/views/error_helpers.ex"},
    {:eex,  "#{@pre}/priv/gettext/errors.pot",        :web, "priv/gettext/errors.pot"},
    {:eex,  "#{@pre}/priv/gettext/en/LC_MESSAGES/errors.po", :web, "priv/gettext/en/LC_MESSAGES/errors.po"},
  ]

  template :brunch, [
    {:text, "assets/brunch/gitignore",        :web, ".gitignore"},
    {:eex,  "assets/brunch/brunch-config.js", :web, "assets/brunch-config.js"},
    {:eex,  "assets/brunch/package.json",     :web, "assets/package.json"},
    {:text, "assets/app.css",                 :web, "assets/css/app.css"},
    {:text, "assets/phoenix.css",             :web, "assets/css/phoenix.css"},
    {:eex,  "assets/brunch/app.js",           :web, "assets/js/app.js"},
    {:eex,  "assets/brunch/socket.js",        :web, "assets/js/socket.js"},
    {:keep, "assets/vendor",                  :web, "assets/vendor"},
    {:text, "assets/robots.txt",              :web, "assets/static/robots.txt"},
  ]

  template :html, [
    {:eex,  "#{@pre}/test/controllers/page_controller_test.exs", :web, "test/controllers/page_controller_test.exs"},
    {:eex,  "#{@pre}/test/views/layout_view_test.exs",           :web, "test/views/layout_view_test.exs"},
    {:eex,  "#{@pre}/test/views/page_view_test.exs",             :web, "test/views/page_view_test.exs"},
    {:eex,  "#{@pre}/lib/controllers/page_controller.ex",        :web, "lib/controllers/page_controller.ex"},
    {:eex,  "#{@pre}/lib/templates/layout/app.html.eex",         :web, "lib/templates/layout/app.html.eex"},
    {:eex,  "#{@pre}/lib/templates/page/index.html.eex",         :web, "lib/templates/page/index.html.eex"},
    {:eex,  "#{@pre}/lib/views/layout_view.ex",                  :web, "lib/views/layout_view.ex"},
    {:eex,  "#{@pre}/lib/views/page_view.ex",                    :web, "lib/views/page_view.ex"},
  ]

  template :bare, [
    {:text, "static/bare/gitignore", :web, ".gitignore"},
  ]

  template :static, [
    {:text,   "assets/bare/gitignore", :web, ".gitignore"},
    {:text,   "assets/app.css",        :web, "priv/static/css/app.css"},
    {:append, "assets/phoenix.css",    :web, "priv/static/css/app.css"},
    {:text,   "assets/bare/app.js",    :web, "priv/static/js/app.js"},
    {:text,   "assets/robots.txt",     :web, "priv/static/robots.txt"},
  ]


  def run([path | _] = args) do
    unless in_umbrella?(path) do
      Mix.raise "the web task can only be run within an umbrella's apps directory"
    end

    Mix.Tasks.Phx.New.run(args, __MODULE__)
  end

  def prepare_project(%Project{project_path: project_path} = project) do
    web_app = :"#{project.app}_web"
    {proj_path, web_path} =
      if project_path do
        {project_path, Path.join(project_path, "apps/#{web_app}/")}
      else
        {Path.expand(project.base_path, "../../"), project.base_path}
      end

    %Project{project |
             web_app: web_app,
             web_namespace: Module.concat(project.app_mod, Web),
             project_path: proj_path,
             web_path: web_path}
  end

  def generate(%Project{} = project) do
    raise inspect project
    copy_from project, __MODULE__, template_files(:new)
    if Project.html?(project), do: gen_html(project)

    case {Project.brunch?(project), Project.html?(project)} do
      {true, _}      -> gen_brunch(project)
      {false, true}  -> gen_static(project)
      {false, false} -> gen_bare(project)
    end

    project
  end

  defp gen_html(%Project{} = project) do
    copy_from project, __MODULE__, template_files(:html)
  end

  defp gen_static(%Project{web_path: web_path} = project) do
    copy_from project, __MODULE__, template_files(:static)
    create_file Path.join(web_path, "priv/static/js/phoenix.js"), phoenix_js_text()
    create_file Path.join(web_path, "priv/static/images/phoenix.png"), phoenix_png_text()
    create_file Path.join(web_path, "priv/static/favicon.ico"), phoenix_favicon_text()
  end

  defp gen_brunch(%Project{web_path: web_path} = project) do
    copy_from project, __MODULE__, template_files(:brunch)
    create_file Path.join(web_path, "assets/static/images/phoenix.png"), phoenix_png_text()
    create_file Path.join(web_path, "assets/static/favicon.ico"), phoenix_favicon_text()
  end

  defp gen_bare(%Project{} = project) do
    copy_from project, __MODULE__, template_files(:bare)
  end
end
