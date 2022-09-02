# danger-rcov

This plugin will provide an interface similar to codecov.

![Screenshot 2020-06-08 at 22 24 18](https://user-images.githubusercontent.com/756762/84170757-e2b8a700-aa71-11ea-8573-da077ec07267.png)



## Installation

    $ gem install danger-rcov

## Usage

  [circleCI] Inside your Dangerfile:

  ```
    # stable branch to check against (default: 'master')
    # build name (default: 'build')
    # warning (default: true)
    markdown rcov.report('master', 'build', true)
  ```

  [Others] Generic

  ```
    # current branch url to coverage.json
    # stable branch url to coverage.json
    # warning (default: true)
    markdown rcov.report_by_urls('http://current_branch/coverage.json', 'http://master_branch/coverage.json', true)
  ```

  ```
    # current branch json report file
    # pr number
    # stable branch json report file
    # stable pr number
    # warning (default: true)
    markdown rcov.report_by_files(current_cov_json_file, current_pr_number, prev_cov_json_file, previous_pr_number, true)
  ```
