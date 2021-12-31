from crystallang/crystal:1.2.2

copy . /agave
workdir /agave

run shards build --production

cmd ["/agave/agave-server"]
