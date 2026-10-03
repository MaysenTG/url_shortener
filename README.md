# URL Shortener

Rails app that turns long URLs into short shareable links, with click tracking.

## Requirements

- Ruby 3.2.0
- PostgreSQL
- Redis (for Action Cable / live click updates)

## Boot

```bash
bundle install
```

Create the database password in Rails credentials (`DB_PASSWORD`), matching your local Postgres user:

```bash
EDITOR="nano" bin/rails credentials:edit
```

Example credentials entry:

```yaml
DB_PASSWORD: your_postgres_password
```

Then:

```bash
bin/rails db:prepare
bin/rails server
```

Open [http://localhost:3000](http://localhost:3000).

Make sure Redis is running locally (`redis://localhost:6379/1` by default in development).
