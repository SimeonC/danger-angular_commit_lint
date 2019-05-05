# AngularJS Format Commit Lint for Danger

[![Build Status](https://travis-ci.org/jonallured/danger-angular_commit_lint.svg?branch=master)](https://travis-ci.org/simeonc/danger-angular_commit_lint)

This is a [Danger Plugin][danger] that ensures nice and tidy commit messages. It is based off [https://github.com/jnallured/danger-commit_lint].
The checks performed on each commit message are inspired by [Angular Commit Format][angular] in use by [standard-version][standard].

[danger]: http://danger.systems/plugins
[angular]: https://gist.github.com/stephenparish/9941e89d80e2bc58a153#allowed-type
[standard]: https://github.com/conventional-changelog/standard-version

## Installation

```
$ gem install danger-angular_commit_lint
```

## Usage

Simply add this to your Dangerfile:

```ruby
angular_commit_lint.check
```

That will check each commit in the PR to ensure the following is true:

* Commit subject follows the angular pattern of `<type>(<scope>): <subject>`
* Commit <subject> begins with a capital letter (`subject_cap`)
* Commit <subject> is more than one word (`subject_words`)
* Commit <subject> is no longer than 50 characters (`subject_length`)
* Commit <subject> does not end in a period (`subject_period`)
* Commit <subject> and body are separated by an empty line (`empty_line`)

By default, Commit Lint fails, but you can configure this behavior.

## Configuration

Configuring Commit Lint is done by passing a hash. The three keys that can be
passed are:

* `disable`
* `fail`
* `warn`

To each of these keys you can pass either the symbol `:all` or an array of
checks. Here are some ways you could configure Commit Lint:

```ruby
# configure how you want your commits to be formatted
angular_commit_lint.check {
  commit_types => ['fix', 'feat'], # an array of types that are accepted, all others give an error
  use_scope => true, # whether you use `(<scope>)` or not
  require_scope => false, # if use_scope is true then this makes the scope optional if true
  min_scope => 1 # minimum length of the `<scope>`
}
```

```ruby
# warn on all checks (instead of failing)
angular_commit_lint.check warn: :all

# disable the `subject_period` check
angular_commit_lint.check disable: [:subject_period]
```

Remember, by default all checks are run and they will fail. Think of this as the
default:

```ruby
angular_commit_lint.check fail: :all
```

Also note that there is one more way that Commit Lint can behave:

```ruby
angular_commit_lint.check disable: :all
```

This will actually throw a warning that Commit Lint isn't doing anything.
