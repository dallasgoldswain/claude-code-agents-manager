# Ruby Tooling Field Manual (Code‑Gen Ready, Production‑Proven)

*Assumption: Ruby 3.2+ and Bundler are already installed and available on `PATH`.*

---

## 0 — Sanity Check

```bash
ruby --version              # verify Ruby installation; should show 3.2+
bundle --version            # verify Bundler installation
gem --version               # verify RubyGems installation
```

If any command fails, halt and report to the user.

---

## 1 — Daily Workflows

### 1.1 New Project Setup

```bash
mkdir myproject && cd myproject
bundle init                     # ① create Gemfile
bundle add rake minitest        # ② add core dependencies
bundle install                  # ③ install gems + create lock
bundle exec rake test           # ④ run tests in project bundle
```

### 1.2 Gem Development Flow

```bash
bundle gem mygem                # create gem scaffold
cd mygem
bundle install                  # install dev dependencies
bundle exec rake test           # run test suite
bundle exec rake build          # build gem package
bundle exec rake install        # install locally
```

### 1.3 CLI Tools Management

```bash
gem install rubocop            # system-wide tool install
gem install yard                # documentation generator
gem install bundler-audit       # security auditing
gem update --system            # update RubyGems itself
```

### 1.4 Ruby Version Management (rbenv)

```bash
rbenv install 3.2.0            # install specific Ruby version
rbenv local 3.2.0              # set project Ruby version
rbenv versions                  # list installed versions
rbenv which ruby                # show current Ruby path
```

### 1.5 Dependency Management

```bash
bundle add gem_name             # add gem to Gemfile + install
bundle add gem_name --group development  # add to specific group
bundle remove gem_name          # remove gem from Gemfile
bundle update gem_name          # update specific gem
bundle outdated                 # show outdated gems
```

---

## 2 — Performance & Configuration

### 2.1 Bundler Configuration

| Setting | Purpose | Command |
|---------|---------|---------|
| `jobs` | Parallel gem installation | `bundle config set --local jobs 4` |
| `path` | Local gem installation path | `bundle config set --local path vendor/bundle` |
| `without` | Skip gem groups | `bundle config set --local without development test` |
| `clean` | Auto-clean unused gems | `bundle config set --local clean true` |

### 2.2 RubyGems Configuration

```bash
echo "gem: --no-document" >> ~/.gemrc    # skip documentation for faster installs
echo "install: --no-document" >> ~/.gemrc
echo "update: --no-document" >> ~/.gemrc
```

### 2.3 Performance Commands

```bash
bundle install --jobs 4        # parallel installation
bundle clean                   # remove unused gems
gem cleanup                    # remove old gem versions
```

---

## 3 — CI/CD Recipes

### 3.1 GitHub Actions

```yaml
# .github/workflows/test.yml
name: Ruby Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        ruby-version: ['3.1', '3.2', '3.3']
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: ${{ matrix.ruby-version }}
          bundler-cache: true           # runs bundle install + caches
      - run: bundle exec rake test
      - run: bundle exec rubocop
```

### 3.2 Docker

```dockerfile
FROM ruby:3.2-alpine

WORKDIR /app

# Install system dependencies
RUN apk add --no-cache build-base sqlite-dev

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment true && \
    bundle config set --local without development test && \
    bundle install

# Copy application code
COPY . .

CMD ["bundle", "exec", "ruby", "app.rb"]
```

---

## 4 — Tool Migration Matrix

| Legacy Tool / Concept | Modern Replacement | Notes |
|-----------------------|-------------------|-------|
| `gem install` (global) | `bundle add` | Project-specific dependency |
| `require 'gem'` | `Gemfile` entry | Explicit dependency declaration |
| `rake` | `bundle exec rake` | Isolated gem environment |
| `rspec` | `bundle exec rspec` | Use bundled version |
| `irb` | `bundle console` | REPL with project gems loaded |
| Manual `$LOAD_PATH` | Bundler auto-require | Automatic gem loading |

---

## 5 — Quality Assurance Tools

### 5.1 Code Quality

```bash
# Linting and style checking
bundle add rubocop --group development
bundle exec rubocop                     # check style violations
bundle exec rubocop -a                  # auto-fix safe violations
bundle exec rubocop --auto-gen-config   # generate .rubocop.yml

# Security auditing
bundle add bundler-audit --group development
bundle exec bundle-audit check          # check for known vulnerabilities
bundle exec bundle-audit update         # update vulnerability database
```

### 5.2 Testing Tools

```bash
# Testing frameworks
bundle add minitest --group development test    # lightweight testing
bundle add rspec --group development test      # behavior-driven testing

# Test coverage
bundle add simplecov --group test
bundle exec rake test                   # run with coverage report

# Performance testing
bundle add benchmark-ips --group development
bundle add memory_profiler --group development
```

### 5.3 Documentation

```bash
bundle add yard --group development
bundle exec yard                        # generate documentation
bundle exec yard server                 # serve docs locally
bundle exec yard stats                  # coverage statistics
```

---

## 6 — Troubleshooting Fast‑Path

| Symptom | Resolution |
|---------|------------|
| `bundle install` fails | `bundle config set --local force_ruby_platform true` |
| Gem compilation errors | Install development headers: `apt-get install ruby-dev` |
| Permission denied | Use `bundle config set --local path vendor/bundle` |
| Old gem versions | `bundle update` or `bundle update gem_name` |
| Missing native extensions | `bundle config set --local build.gem_name --with-opt-dir=/usr/local` |
| Slow bundle install | `bundle config set --local jobs $(nproc)` |

---

## 7 — Project Structure Best Practices

```text
myproject/
├── Gemfile                    # dependency specification
├── Gemfile.lock              # locked dependency versions (commit this)
├── Rakefile                  # task definitions
├── lib/
│   └── myproject/            # main library code
│       ├── version.rb        # version constant
│       └── *.rb              # implementation files
├── bin/                      # executable scripts
├── test/ or spec/            # test files
├── .ruby-version             # Ruby version specification
├── .rubocop.yml             # linting configuration
└── README.md                # project documentation
```

---

## 8 — Agent Cheat‑Sheet (Copy/Paste)

```bash
# new project
mkdir myproj && cd myproj && bundle init && bundle add rake minitest

# add dependencies
bundle add nokogiri httparty
bundle add rspec --group test

# run tasks
bundle exec rake test
bundle exec rubocop -a

# gem development
bundle gem mygem && cd mygem && bundle install

# quality checks
bundle exec bundle-audit check
bundle exec yard stats

# update dependencies
bundle outdated
bundle update
```

---

## 9 — Ruby Ecosystem Tools

### 9.1 Essential Development Gems

```ruby
# Gemfile development group
group :development do
  gem 'rubocop'              # code style and linting
  gem 'yard'                 # documentation generation
  gem 'pry'                  # debugging REPL
  gem 'bundler-audit'        # security vulnerability scanner
end

group :test do
  gem 'minitest'             # testing framework
  gem 'simplecov'            # code coverage
  gem 'factory_bot'          # test data factories
end
```

### 9.2 Performance Tools

```bash
# Profiling and benchmarking
bundle add ruby-prof --group development        # detailed profiling
bundle add benchmark-ips --group development    # iterations per second
bundle add memory_profiler --group development  # memory usage analysis
bundle add stackprof --group development        # statistical profiler
```

---

*End of manual*