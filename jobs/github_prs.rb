require 'octokit'

SCHEDULER.every '1m', :first_in => 0 do |job|
  load_params = YAML::load_file('config/application.yml')
  github_params = load_params['github'].symbolize_keys
  
  client = Octokit::Client.new(:access_token => github_params[:github_token])
  my_organization = github_params[:github_org]
  repos = client.organization_repositories(my_organization).map { |repo| repo.name }

  open_pull_requests = repos.inject([]) { |pulls, repo|
    client.pull_requests("#{my_organization}/#{repo}", :state => 'open').each do |pull|
      pulls.push({
        title: pull.title,
        repo: repo,
        updated_at: pull.updated_at.strftime("%b %-d %Y, %l:%m %p"),
        creator: "@" + pull.user.login,
        })
    end
    pulls
  }

  send_event('pull_requests', { header: "Open Pull Requests", pulls: open_pull_requests })
end
