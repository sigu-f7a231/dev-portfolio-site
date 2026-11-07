# services/auth-phoenix/Dockerfile
#
# 1. elixir のイメージで依存を取り、mix release で動かすものを作る
# 2. 同じ elixir のイメージに、できたものだけを写して動かす（OTP・libc の版がそろうので、別のイメージより安全）
# - mix.lock があれば版をそろえる。まだなければ mix deps.get が作る
FROM elixir:1.18-alpine AS build

RUN apk add --no-cache build-base git
WORKDIR /app
ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock* ./
RUN mix deps.get --only prod

# コンパイルのときに使う設定を先に
COPY config/config.exs config/prod.exs config/
RUN mix deps.compile

COPY lib lib
RUN mix compile

# 起動のときに読む設定（環境変数）
COPY config/runtime.exs config/
RUN mix release

FROM elixir:1.18-alpine

WORKDIR /app
ENV MIX_ENV=prod \
    PORT=4100

# nobody で動かす（手元のファイルの権限によらず読めるように --chown）
COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/auth_service ./
USER nobody

EXPOSE 4100
CMD ["/app/bin/auth_service", "start"]
